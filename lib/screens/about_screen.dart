// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT
import 'package:community_material_icon/community_material_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Über uns'),
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-Bild oder Icon (optional)
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1), // ✅ THEME FARBE
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: Image.asset(
                    'assets/logos/aps.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
            // Hauptüberschrift
            Text(
              'Die Mission von AlpenPreisGrenze',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            // Beschreibungstext
            Text(
              'Willkommen bei AlpenPreisGrenze! Ihrer Stop Österreich-Aufschlag App! Wir glauben daran, '
              'dass jeder Käufer das Recht auf einen fairen und transparenten '
              'Einzelhandel hat. Unser Ziel ist es, im kollektiven gemeinschaftichen Handeln '
              'Druck auf den Einzelhandel auszuüben bis dieser seine unfairen Praktiken uns Österreichern gegenüber einstellt.',
              style: TextStyle(
                fontSize: AppTypography.bodyLarge, // ✅ THEME TYPOGRAFIE
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
            // Hauptpunkte als Karten
            _buildInfoCard(
              context,
              icon: CommunityMaterialIcons.barcode,
              title: 'Österreich-Aufschläge entdecken',
              content:
                  'Jeder Nutzer von AlpenPreisGrenze kann eigenständig '
                  'Preisvergleiche im Handel durchführen. Dazu wird einfach der Barcode des Produktes gescannt '
                  'und die App zeigt sofort die Höhe des Österreich-Aufschlages an.',
            ),

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppRadius.large,
                ), // ✅ THEME RADIUS
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          child: Stack(
                            alignment: Alignment
                                .center, // Zentriert das innere Icon im äußeren
                            children: [
                              Icon(
                                Icons.border_outer, // Äußeres Icon (großes Quadrat)
                                size: 32,
                                color: AppColors.primary,
                              ),
                  Icon(
                                  Icons
                                      .arrow_downward, // Inneres Icon (Pfeil nach unten)
                                  size:
                                      32 *
                                      0.6, // Passe die Größe des inneren Icons an (z.B. 60% der äußeren Größe)
                                  color: AppColors.primary,
                                ),
                           
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                        Expanded(
                          child: Text(
                            'Shrinkflation entdecken',
                            style: TextStyle(
                              fontSize:
                                  AppTypography.body, // ✅ THEME TYPOGRAFIE
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary, // ✅ THEME FARBE
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                    Text(
                      'Manchmal sind die Preise nicht '
                      'signifikant unterschiedlich. Allerdings wird still und heimlich die Menge '
                      'reduziert (Shrinkflation). Unsere App erkennt solche Praktiken und macht Sie darauf aufmerksam.',

                      style: TextStyle(
                        fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                        color: AppColors.textPrimary, // ✅ THEME FARBE
                      ),
                    ),
                  ],
                ),
              ),
            ),


            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildInfoCard(
              context,
              icon: Icons.balance,
              title: 'Sizefuscation entdecken',
              content:
                  'Um Preisunterschiede zu verstecken werden auch handelunübliche Mengen und '
                  'Verpackungsgrößen eingeführt. Z.B. gibt es bestimmte Getränke in Deutschland nicht in handelsüblichen '
                  '1,5L sondern nur in 1,25L. Damit ist der Preisunterschied nicht so dramatisch auch wenn er auf den Literpreis umgerechnet über 100% beträgt. Unsere App erkennt auch solche Praktiken und macht Sie darauf aufmerksam.',
            ),

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildInfoCard(
              context,
              icon: Icons.share,
              title: 'Entdeckungen teilen',
              content:
                  'Nutzer können ihre Entdeckungen auf Social-Media Plattformen '
                  'teilen. Je mehr Menschen über die Aufschläge informiert sind, '
                  'umso mehr Druck können wir gemeinsam auf den Einzelhandel ausüben.',
            ),

            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildInfoCard(
              context,
              icon: Icons.warning,
              title: 'Beschwerde E-Mails senden',
              content:
                  'Nutzer können direkt aus der App heraus vorgefertigte E-Mails '
                  'an den jeweiligen Kundensupport des Konzerns versenden! Die E-Mails '
                  'enthalten die Preisvergleichsdaten und eine Aufforderung zu erklären wie die Differenz gerechtfertigt wird.',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
            // Zusätzliche Punkte
            Text(
              'Weitere Vorteile',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND

            _buildFeatureItem(
              context,
              'Transparente Preisvergleiche',
              'Einfache und schnelle Preisvergleiche zwischen Österreich und Deutschland',
            ),

            _buildFeatureItem(
              context,
              'Community-basiert',
              'Gemeinschaftliches Handeln - keine kommerziellen Interessen',
            ),

            _buildFeatureItem(
              context,
              'Aktuelle Informationen',
              'Immer auf dem neuesten Stand über aktuelle Preisunterschiede',
            ),

            _buildFeatureItem(
              context,
              'Kostenlos & unabhängig',
              'Keine versteckten Kosten oder Gebühren',
            ),

            _buildFeatureItem(
              context,
              'Datenschutz',
              'Ihre Daten gehören Ihnen - wir respektieren Ihre Privatsphäre',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
            // Abschluss-Text
            Container(
              padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // ✅ THEME FARBE
                borderRadius: BorderRadius.circular(
                  AppRadius.large,
                ), // ✅ THEME RADIUS
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.handshake,
                    size: 40,
                    color: AppColors.primary, // ✅ THEME FARBE
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Text(
                    'Gemeinsam für fairen Einzelhandel!',
                    style: TextStyle(
                      fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary, // ✅ THEME FARBE
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
                  Text(
                    'Treten Sie unserer Community bei und tragen Sie dazu bei, '
                    'den unfairen Österreich-Aufschlag zu beenden.',
                    style: TextStyle(
                      fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                      color: AppColors.textPrimary, // ✅ THEME FARBE
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
            // Kontakt-Info (optional)
            Text(
              'Haben Sie Fragen oder Feedback?',
              style: TextStyle(
                fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            Text(
              'Wir freuen uns über Ihre Rückmeldung! Kontaktieren Sie uns über '
              'die Einstellungen oder schreiben Sie uns direkt eine E-Mail-Nachricht.',
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
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
            Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: AppColors.primary, // ✅ THEME FARBE
                ),
                SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // ✅ THEME FARBE
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
            Text(
              content,
              style: TextStyle(
                fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                color: AppColors.textPrimary, // ✅ THEME FARBE
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.s), // ✅ THEME ABSTAND
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primary, // ✅ THEME FARBE
            size: 20,
          ),
          SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary, // ✅ THEME FARBE
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                    color: AppColors.textSecondary, // ✅ THEME FARBE
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
