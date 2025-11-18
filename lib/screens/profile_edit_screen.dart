import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_price_tracker_app/services/image_upload_service.dart';
import 'package:my_price_tracker_app/services/rate_limit_service.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();

  File? _profileImageFile;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _loadUserProfile();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            _usernameController.text =
                userData['username'] ?? _currentUser!.displayName ?? 'Mieter';
            _currentProfileImageUrl = userData['profileImageUrl'];
          });
        }
      } else {
        final username =
            _currentUser!.displayName ??
            _currentUser!.email?.split('@')[0] ??
            'Mieter';

        await _firestore.collection('users').doc(_currentUser!.uid).set({
          'uid': _currentUser!.uid,
          'email': _currentUser!.email,
          'username': username,
          'createdAt': DateTime.now(),
          'lastLogin': DateTime.now(),
          'profileImageUrl': '',
        });

        setState(() {
          _usernameController.text = username;
        });
      }
    } catch (e) {
      print('Fehler beim Laden des Profils: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Laden des Profils')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _profileImageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Auswählen des Bildes')),
      );
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    if (_currentUser == null) return null;

    final canChange = await RateLimitService.canUserChangeProfileImage(
      _currentUser!.uid,
    );

    if (!canChange) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profilbild-Limit erreicht: Nur einmal pro Woche möglich',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return _currentProfileImageUrl;
    }

    try {
      print('Optimiere Bild...');
      final optimizedImage = await ImageUploadService.optimizeForMobile(
        imageFile,
      );
      print('Bild optimiert: ${optimizedImage.path}');

      print('Lade Bild hoch...');
      String fileName =
          'user_${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/${_currentUser!.uid}/$fileName',
      );

      UploadTask uploadTask = storageRef.putFile(optimizedImage);
      TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 30));
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Bild erfolgreich hochgeladen: $downloadUrl');

      if (optimizedImage.path != imageFile.path) {
        await optimizedImage.delete();
        print('Temporäre Datei gelöscht.');
      }

      await RateLimitService.updateProfileImageChangeDate(_currentUser!.uid);
      print('Datum der letzten Änderung aktualisiert.');

      return downloadUrl;
    } catch (e) {
      print('Fehler beim Upload des Profilbildes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Upload des Profilbildes'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        throw Exception('Benutzername darf nicht leer sein');
      }

      String? profileImageUrl = _currentProfileImageUrl;
      if (_profileImageFile != null) {
        profileImageUrl = await _uploadProfileImage(_profileImageFile!);
        if (profileImageUrl == null) {
          throw Exception('Fehler beim Upload des Profilbildes');
        }
      }

      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'updatedAt': DateTime.now(),
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil erfolgreich gespeichert!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Fehler beim Speichern des Profils: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern des Profils')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil bearbeiten'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving || _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileImageSection(),
                  SizedBox(height: AppSpacing.xxl),

                  _buildUsernameSection(),
                  SizedBox(height: AppSpacing.xxl),

                  _buildEmailSection(),
                  SizedBox(height: AppSpacing.xxl),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving || _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.m,
                          horizontal: AppSpacing.xl,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                                SizedBox(width: AppSpacing.s),
                                Text(
                                  'Speichern...',
                                  style: TextStyle(
                                    fontSize: AppTypography.body,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Profil speichern',
                              style: TextStyle(
                                fontSize: AppTypography.body,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profilbild',
              style: TextStyle(
                fontSize: AppTypography.headline3,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.m),

            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textDisabled,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _profileImageFile != null
                          ? Image.file(
                              _profileImageFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildProfileImagePlaceholder();
                              },
                            )
                          : _currentProfileImageUrl != null &&
                                _currentProfileImageUrl!.isNotEmpty
                          ? Image.network(
                              _currentProfileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildProfileImagePlaceholder();
                              },
                            )
                          : _buildProfileImagePlaceholder(),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _pickProfileImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.m),

            Center(
              child: TextButton(
                onPressed: _pickProfileImage,
                child: Text('Profilbild ändern'),
              ),
            ),

            Center(
              child: Text(
                'Unterstützte Formate: JPG, PNG (max. 5MB empfohlen)',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePlaceholder() {
    return Container(
      color: AppColors.cardBackground,
      child: Icon(Icons.person, color: AppColors.textSecondary, size: 50),
    );
  }

  Widget _buildUsernameSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benutzername',
              style: TextStyle(
                fontSize: AppTypography.headline3,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.m),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Benutzername *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                prefixIcon: Icon(Icons.person),
                hintText: 'Geben Sie Ihren Benutzernamen ein',
              ),
              maxLength: 30,
              enabled: !_isSaving,
            ),

            SizedBox(height: AppSpacing.s),

            Text(
              'Ihr Benutzername wird in Bewertungen angezeigt',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Mail Adresse',
              style: TextStyle(
                fontSize: AppTypography.headline3,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.m),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.m,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textDisabled),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: AppColors.textSecondary),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      _currentUser?.email ?? 'Keine E-Mail',
                      style: TextStyle(fontSize: AppTypography.body),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
