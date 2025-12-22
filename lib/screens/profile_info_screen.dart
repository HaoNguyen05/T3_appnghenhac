import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  late AuthService auth;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final avatarController = TextEditingController();

  String? avatarUrl;
  bool isLoading = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    auth = Provider.of<AuthService>(context, listen: false);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = auth.user;
    if (user == null) return;

    final data =
        await supabase.from('users').select().eq('id', user.id).maybeSingle();

    setState(() {
      nameController.text = data?['name'] ?? '';
      avatarUrl = data?['avatar_url'];
      avatarController.text = data?['avatar_url'] ?? '';
      emailController.text = user.email ?? '';
    });
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final bytes = await file.readAsBytes();

      final fileName =
          '${auth.user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      setState(() {
        avatarUrl = publicUrl;
        avatarController.text = publicUrl; // ⭐ sync với input
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload ảnh lỗi: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= SAVE =================
  Future<void> _saveProfile() async {
    final supabase = Supabase.instance.client;
    final user = auth.user;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final newEmail = emailController.text.trim();
      final currentEmail = user.email ?? '';
      final newAvatarUrl = avatarController.text.trim();

      // 1️⃣ Update email auth
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        await supabase.auth.updateUser(
          UserAttributes(email: newEmail),
        );
      }

      // 2️⃣ Upsert profile (EMAIL BẮT BUỘC)
      await supabase.from('users').upsert({
        'id': user.id,
        'email': newEmail.isNotEmpty ? newEmail : currentEmail,
        'name': nameController.text.trim(),
        'avatar_url': newAvatarUrl.isNotEmpty ? newAvatarUrl : avatarUrl,
      });

      setState(() {
        avatarUrl = newAvatarUrl.isNotEmpty ? newAvatarUrl : avatarUrl;
        isEditing = false;
      });

      // Update AuthService
      final updatedProfile = UserProfile(
        id: user.id,
        email: newEmail.isNotEmpty ? newEmail : currentEmail,
        name: nameController.text.trim(),
        avatarUrl: newAvatarUrl.isNotEmpty ? newAvatarUrl : avatarUrl,
      );
      auth.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thông tin cá nhân')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Chưa đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: isLoading
                ? null
                : () => isEditing
                    ? _saveProfile()
                    : setState(() => isEditing = true),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(
                    avatarUrl ?? 'https://i.pravatar.cc/150?img=3',
                  ),
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _pickImage,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== NAME =====
            TextField(
              controller: nameController,
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),

            const SizedBox(height: 16),

            // ===== EMAIL =====
            TextField(
              controller: emailController,
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            const SizedBox(height: 16),

            // ===== AVATAR URL (DÁN LINK) =====
            TextField(
              controller: avatarController,
              enabled: isEditing,
              decoration: const InputDecoration(
                labelText: 'Avatar URL',
                hintText: 'https://...',
              ),
              onChanged: (value) {
                setState(() {
                  avatarUrl =
                      value.trim().isNotEmpty ? value.trim() : avatarUrl;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
