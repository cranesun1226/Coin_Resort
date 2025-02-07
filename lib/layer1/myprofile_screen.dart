// dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _profileImage;
  String _profileImageUrl = '';
  bool _isLoading = false;
  List<dynamic> _feeds = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFeeds();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    // 프로필 조회 (profiles 테이블)
    final response =
        await _supabase.from('profiles').select().eq('id', user.id).single();
    if (response.isNotEmpty) {
      final data = response;
      setState(() {
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _profileImageUrl = data['profile_img'] ?? ''; // 프로필 이미지 URL 저장
      });
    }
  }

  Future<void> _loadFeeds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    // feed 혹은 message 데이터 불러오기 (feeds 테이블로 가정)
    final response = await _supabase
        .from('btc_feed')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    if (response.isNotEmpty) {
      setState(() {
        _feeds = response as List;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file, String userId) async {
    try {
      final storage = _supabase.storage;
      final fileExt = file.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final publicUrl =
          '${storage.from('avatars').getPublicUrl(fileName)}?v=${DateTime.now().millisecondsSinceEpoch}';

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('Storage 오류: ${e.message}, 상태 코드: ${e.statusCode}');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImage(_profileImage!, user.id);
      }

      final data = {
        'id': user.id,
        'username': _usernameController.text,
        'bio': _bioController.text,
        if (imageUrl != null) 'profile_img': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').upsert(data);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('프로필이 업데이트되었습니다.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 수정 섹션
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF4A90E2)
                            .withOpacity(0.15), // 더 현대적인 파란색, 투명도 15%
                        backgroundImage: _getProfileImage(),
                        child:
                            (_profileImage == null && _profileImageUrl.isEmpty)
                                ? const Icon(Icons.camera_alt,
                                    size: 40,
                                    color: Color(0xFF007AFF)) // 더 현대적인 파란색
                                : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 닉네임 입력
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        prefixIcon:
                            const Icon(Icons.person, color: Color(0xFF007AFF)),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '닉네임을 입력하세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 한 줄 소개 입력
                    TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: '한 줄 소개',
                        prefixIcon:
                            const Icon(Icons.edit, color: Color(0xFF50E3C2)),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '한 줄 소개를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // 업데이트 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF50E3C2),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                '프로필 업데이트',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 구분선
            const Divider(thickness: 8, color: Color(0xFFF5F7FA)),

            // 내 피드 섹션
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 피드',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _feeds.isEmpty
                      ? const Center(
                          child: Text('게시글이 없습니다.',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _feeds.length,
                          itemBuilder: (context, index) {
                            final feed = _feeds[index] as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2EC4B6)
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feed['title'] ?? '제목 없음',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feed['content'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feed['created_at']
                                            ?.toString()
                                            .substring(0, 16) ??
                                        '',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_profileImageUrl.isNotEmpty) {
      return NetworkImage(_profileImageUrl);
    }
    return null;
  }
}
