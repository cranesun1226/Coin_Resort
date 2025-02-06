// import packages
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
// import files
import 'package:cr_frontend/layer0/homepage_screen.dart';
import 'package:path/path.dart' as path;

class CoinResortSignupScreen extends StatefulWidget {
  const CoinResortSignupScreen({super.key});

  @override
  State<CoinResortSignupScreen> createState() => _CoinResortSignupScreenState();
}

class _CoinResortSignupScreenState extends State<CoinResortSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  XFile? _profileImage;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<String?> _uploadImageToSupabase(XFile imageFile, String userId) async {
    try {
      final storage = Supabase.instance.client.storage;
      final fileExt = path.extension(imageFile.path);
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}$fileExt';

      final bytes = await imageFile.readAsBytes();

      await storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
                contentType: 'image/${fileExt.replaceAll('.', '')}',
                upsert: true),
          );

      return storage.from('avatars').getPublicUrl(fileName);
    } on StorageException catch (e) {
      debugPrint('Storage 오류: ${e.message}, 상태 코드: ${e.statusCode}');
      throw '이미지 업로드 중 오류가 발생했습니다.';
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userId = user.id;
        String? imageUrl;

        // **이미지 업로드 후 URL 저장**
        if (_profileImage != null) {
          imageUrl = await _uploadImageToSupabase(_profileImage!, userId);
        }

        final data = {
          'id': userId,
          'username': _usernameController.text,
          'bio': _bioController.text,
          'profile_img': imageUrl ?? '', // 이미지 없으면 빈 값
          'updated_at': DateTime.now().toIso8601String(),
        };

        await Supabase.instance.client.from('profiles').upsert(data);

        if (mounted) {
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const CoinResortHomePage()),
            (route) => false,
          );
        }
      } else {
        throw 'User not authenticated';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2EC4B6), // Mint Green
              Color(0xFFFF7F50), // Sunset Orange
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt,
                                color: Color(0xFFFF7F50), size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: '닉네임',
                              prefixIcon: const Icon(Icons.person,
                                  color: Color(0xFFFF7F50)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '닉네임을 입력하세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _bioController,
                            decoration: InputDecoration(
                              labelText: '한 줄 소개',
                              prefixIcon: const Icon(Icons.edit,
                                  color: Color(0xFFFF7F50)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '한 줄 소개를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitData,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 45, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Color(0xFF2EC4B6)) // Mint Green)
                                : const Text(
                                    '가입하기',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF7F50),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
