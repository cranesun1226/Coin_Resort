import 'package:cr_frontend/layer3/smallchart_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateFeedScreen extends StatefulWidget {
  final String code;

  const CreateFeedScreen({super.key, required this.code});

  @override
  State<CreateFeedScreen> createState() => _CreateFeedScreenState();
}

class _CreateFeedScreenState extends State<CreateFeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _entryPriceController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _reasonController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> _submitFeed() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');

      await supabase
          .from('${widget.code.split('-')[1].toLowerCase()}_feed')
          .insert({
        'user_id': user.id,
        'title': _titleController.text,
        'entry_price': double.parse(_entryPriceController.text),
        'target_price': double.parse(_targetPriceController.text),
        'reason': _reasonController.text,
      });

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드 작성 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('피드 작성',
            style: TextStyle(
                color: Color(0xFF2D3436),
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2EC4B6)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: 250,
                child: SmallChartWidget(
                  interval: 15,
                  code: widget.code,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _titleController,
              label: '제목',
              hint: '매매 제목을 입력해주세요',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _entryPriceController,
              label: '진입가격',
              hint: '진입 가격을 입력해주세요',
              icon: Icons.trending_up,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _targetPriceController,
              label: '목표가격',
              hint: '목표 가격을 입력해주세요',
              icon: Icons.flag,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _reasonController,
              label: '매매 이유',
              hint: '매매 이유를 상세히 작성해주세요',
              icon: Icons.description,
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EC4B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                '피드 올리기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2EC4B6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: const TextStyle(color: Color(0xFF2D3436)),
          hintStyle: TextStyle(color: const Color(0xFF2D3436).withOpacity(0.5)),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return '$label을(를) 입력해주세요';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _entryPriceController.dispose();
    _targetPriceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
