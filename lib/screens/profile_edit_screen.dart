// lib/screens/profile_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_price_tracker_app/services/image_upload_service.dart';
import 'package:my_price_tracker_app/services/rate_limit_service.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

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
  User? _currentUser; // Firebase Auth User

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _loadUserProfile();
    } else {
      // Falls kein User eingeloggt ist
      Navigator.pop(context);
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Lade User-Daten aus Firestore
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
        // Erstelle neuen User-Eintrag mit Firebase Auth Daten
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

    // Prüfe Profilbild-Limit
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
      return _currentProfileImageUrl; // Altes Bild behalten
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
      // Validiere Username
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        throw Exception('Benutzername darf nicht leer sein');
      }

      // Upload Profilbild falls geändert
      String? profileImageUrl = _currentProfileImageUrl;
      if (_profileImageFile != null) {
        profileImageUrl = await _uploadProfileImage(_profileImageFile!);
        if (profileImageUrl == null) {
          throw Exception('Fehler beim Upload des Profilbildes');
        }
      }

      // Speichere Profildaten in Firestore
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

      Navigator.pop(context, true); // Erfolg zurückgeben
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
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
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
              padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profilbild-Abschnitt
                  _buildProfileImageSection(),
                  SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
                  // Username-Abschnitt
                  _buildUsernameSection(),
                  SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
                  // Email-Anzeige (nicht editierbar)
                  _buildEmailSection(),
                  SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
                  // Speichern-Button
                  // Speichern-Button (konsistent mit App-Design)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppRadius.large,
                      ), // ✅ THEME RADIUS
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(
                            0.3,
                          ), // ✅ THEME FARBE
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving || _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.m, // ✅ THEME ABSTAND
                          horizontal: AppSpacing.xl, // ✅ THEME ABSTAND
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.large,
                          ), // ✅ THEME RADIUS
                        ),
                        backgroundColor: AppColors.primary, // ✅ THEME FARBE
                        foregroundColor: Colors.white,
                        elevation: 0, // Entferne Standard-Elevation
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                                SizedBox(
                                  width: AppSpacing.s,
                                ), // ✅ THEME ABSTAND
                                Text(
                                  'Speichern...',
                                  style: TextStyle(
                                    fontSize: AppTypography
                                        .body, // ✅ THEME TYPOGRAFIE
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Profil speichern',
                              style: TextStyle(
                                fontSize:
                                    AppTypography.body, // ✅ THEME TYPOGRAFIE
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
        borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profilbild',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            // Profilbild-Anzeige
            Center(
              child: Stack(
                children: [
                  // Aktuelles Profilbild oder Platzhalter
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textDisabled, // ✅ THEME FARBE
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

                  // Bearbeiten-Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary, // ✅ THEME FARBE
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

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            // Bild-Ändern-Button
            Center(
              child: TextButton(
                onPressed: _pickProfileImage,
                child: Text('Profilbild ändern'),
              ),
            ),

            // Hinweis
            Center(
              child: Text(
                'Unterstützte Formate: JPG, PNG (max. 5MB empfohlen)',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                  color: AppColors.textSecondary, // ✅ THEME FARBE
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
      color: AppColors.cardBackground, // ✅ THEME FARBE
      child: Icon(
        Icons.person,
        color: AppColors.textSecondary, // ✅ THEME FARBE
        size: 50,
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benutzername',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Benutzername *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ), // ✅ THEME RADIUS
                ),
                prefixIcon: Icon(Icons.person),
                hintText: 'Geben Sie Ihren Benutzernamen ein',
              ),
              maxLength: 30,
              enabled: !_isSaving,
            ),

            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND

            Text(
              'Ihr Benutzername wird in Bewertungen angezeigt',
              style: TextStyle(
                fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                color: AppColors.textSecondary, // ✅ THEME FARBE
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
        borderRadius: BorderRadius.circular(AppRadius.large), // ✅ THEME RADIUS
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Mail Adresse',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s, // ✅ THEME ABSTAND
                vertical: AppSpacing.m, // ✅ THEME ABSTAND
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.textDisabled, // ✅ THEME FARBE
                ),
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ), // ✅ THEME RADIUS
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: AppColors.textSecondary, // ✅ THEME FARBE
                  ),
                  SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                  Expanded(
                    child: Text(
                      _currentUser?.email ?? 'Keine E-Mail',
                      style: TextStyle(
                        fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                      ),
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
