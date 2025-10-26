// lib/screens/legal/legal_screen.dart
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

class LegalScreen extends StatelessWidget {
  final String documentType; // 'privacy', 'terms', 'imprint'

  const LegalScreen({Key? key, required this.documentType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (documentType) {
      case 'privacy':
        return _buildPrivacyPolicy(context);
      case 'terms':
        return _buildTermsAndConditions(context);
      case 'imprint':
        return _buildImprint(context);
      default:
        return _buildNotFound(context);
    }
  }

  Widget _buildPrivacyPolicy(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datenschutzerklärung'), 
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datenschutzerklärung',
              style: TextStyle(
                fontSize: AppTypography.headline2, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            Text(
              'Stand: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: TextStyle(
                fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                color: AppColors.textSecondary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            _buildSection(
              context,
              '1. Verantwortlicher',
              'Verantwortlicher im Sinne der Datenschutz-Grundverordnung (DSGVO) ist:\n\n'
                  'Boban Milanovic, BSc\n'
                  'Hormayrstr. 12\n'
                  '6020 Innsbruck\n'
                  'E-Mail: boban.milanovic@email.de\n\n',
            ),

            _buildSection(
              context,
              '2. Erfasste Daten',
              'Wir erfassen und verarbeiten folgende personenbezogene Daten:\n\n'
                  '• Kontodaten: E-Mail-Adresse, Passwort (verschlüsselt)\n'
                  '• Profildaten: Benutzername, Profilbild (optional)\n'
                  '• Preisdaten: Produkte und Produktpreise von Lebensmitteln (Onlineshops, stationärer Handel)\n'
                  '• Technische Daten: Geräteinformationen zur App-Funktionalität\n\n'
                  'Wir erfassen keine Standortdaten, IP-Adressen oder detaillierte Nutzungsstatistiken.',
            ),

            _buildSection(
              context,
              '3. Zwecke der Datenverarbeitung',
              'Wir verarbeiten Ihre personenbezogenen Daten zu folgenden Zwecken:\n\n'
                  '• Bereitstellung und Betrieb der App\n'
                  '• Anzeige von Preisen und Preisdifferenzen\n'
                  '• Nutzerregistrierung und -authentifizierung\n'
                  '• Veröffentlichung von Preisen und Preisdifferenzen\n'
                  '• Kommunikation mit Nutzern (z.B. Passwort-Zurücksetzung)\n'
                  '• Rechtliche Compliance',
            ),

            _buildSection(
              context,
              '4. Rechtsgrundlagen',
              'Die Verarbeitung personenbezogener Daten erfolgt auf folgenden Rechtsgrundlagen:\n\n'
                  '• Art. 6 Abs. 1 lit. a DSGVO: Einwilligung des Nutzers\n'
                  '• Art. 6 Abs. 1 lit. b DSGVO: Erfüllung eines Vertrags\n'
                  '• Art. 6 Abs. 1 lit. f DSGVO: Berechtigte Interessen\n\n'
                  'Die berechtigten Interessen umfassen den Betrieb der App und die Verbesserung der Nutzererfahrung.',
            ),

            _buildSection(
              context,
              '5. Speicherdauer',
              'Wir speichern personenbezogene Daten nur so lange, wie es für die Erfüllung der Zwecke erforderlich ist:\n\n'
                  '• Kontodaten: Solange das Konto aktiv ist\n'
                  '• Preisvergleiche: Dauerhaft (öffentlich sichtbar)\n'
                  '• Profildaten: Solange das Konto aktiv ist\n\n'
                  'Nach Kontolöschung werden alle personenbezogenen Daten gelöscht. Preise und Produkte bleiben anonymisiert erhalten.',
            ),

            _buildSection(
              context,
              '6. Datenweitergabe',
              'Eine Weitergabe personenbezogener Daten an Dritte erfolgt nur in folgenden Fällen:\n\n'
                  '• Mit Ihrer ausdrücklichen Einwilligung\n'
                  '• An technische Dienstleister (z.B. Google-Cloud-Anbieter Firebase)\n'
                  '• Zur Erfüllung rechtlicher Verpflichtungen\n\n'
                  'Wir geben Ihre Daten nicht zu Marketingzwecken oder an Werbetreibende weiter.',
            ),

            _buildSection(
              context,
              '7. Ihre Rechte',
              'Als betroffene Person haben Sie folgende Rechte:\n\n'
                  '• Recht auf Auskunft (Art. 15 DSGVO): Informationen über gespeicherte Daten\n'
                  '• Recht auf Berichtigung (Art. 16 DSGVO): Korrektur falscher Daten\n'
                  '• Recht auf Löschung (Art. 17 DSGVO): Löschen personenbezogener Daten\n'
                  '• Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO)\n'
                  '• Recht auf Datenübertragbarkeit (Art. 20 DSGVO): Erhalt der eigenen Daten\n'
                  '• Widerspruchsrecht (Art. 21 DSGVO): Widerspruch gegen Datenverarbeitung\n'
                  '• Recht auf Widerruf der Einwilligung (Art. 7 Abs. 3 DSGVO)\n\n'
                  'Wichtiger Hinweis: Das Recht auf Löschung betrifft Ihre personenbezogenen Daten (Konto, Profil).\n\n'
                  'Sie können diese Rechte gegenüber dem Verantwortlichen geltend machen.',
            ),

            _buildSection(
              context,
              '8. Sicherheit',
              'Wir treffen angemessene technische und organisatorische Maßnahmen, um Ihre personenbezogenen Daten zu schützen:\n\n'
                  '• Verschlüsselung der Datenübertragung (SSL/TLS)\n'
                  '• Sichere Passwortspeicherung (Verschlüsselung)\n'
                  '• Zugriffskontrollen\n'
                  '• Regelmäßige Sicherheitsupdates',
            ),

            _buildSection(
              context,
              '9. Kontakt',
              'Bei Fragen zum Datenschutz können Sie sich jederzeit an uns wenden:\n\n'
                  'E-Mail: boban.milanovic+pricetracking@gmail.com\n\n'
                  'Sie haben auch das Recht, sich bei einer Aufsichtsbehörde zu beschweren.',
            ),

            _buildSection(
              context,
              '10. Änderungen',
              'Wir behalten uns vor, diese Datenschutzerklärung anzupassen, wenn sich die rechtlichen Rahmenbedingungen oder unsere Dienste ändern. Die aktuelle Version ist stets in der App einsehbar.',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Allgemeine Geschäftsbedingungen'),
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allgemeine Geschäftsbedingungen',
              style: TextStyle(
                fontSize: AppTypography.headline2, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
            Text(
              'Stand: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: TextStyle(
                fontSize: AppTypography.bodySmall, // ✅ THEME TYPOGRAFIE
                color: AppColors.textSecondary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            _buildSection(
              context,
              '1. Geltungsbereich',
              'Diese Allgemeinen Geschäftsbedingungen (AGB) gelten für die Nutzung der Preisvergleichs-App "AlpenPreisGrenze" (nachfolgend "App") und alle damit verbundenen Dienstleistungen. Durch die Registrierung und Nutzung der App erklären Sie sich mit diesen AGB einverstanden.',
            ),

            _buildSection(
              context,
              '2. Vertragsgegenstand',
              'Die App ermöglicht es registrierten Nutzern, Preisvergleiche zwischen Österreich und Deutschland zu erstellen, diese in SocialMedia zu teilen aber auch eine E-Mail an den Kundensupport des jeweiligen Unternehmens zu senden. Die App dient ausschließlich Informationszwecken.',
            ),

            _buildSection(
              context,
              '3. Registrierung und Nutzerkonto',
              '3.1 Die Nutzung bestimmter Funktionen der App erfordert eine Registrierung.\n\n'
                  '3.2 Bei der Registrierung sind vollständige und korrekte Angaben zu machen.\n\n'
                  '3.3 Der Nutzer ist verpflichtet, seine Zugangsdaten geheim zu halten und vor dem unbefugten Zugriff Dritter zu schützen.\n\n'
                  '3.4 Der Nutzer ist verpflichtet, Änderungen seiner Daten unverzüglich mitzuteilen.',
            ),

            _buildSection(
              context,
              '4. Nutzungsrechte',
              '4.1 Die App ist für die private, nicht-kommerzielle Nutzung bestimmt.\n\n'
                  '4.2 Dem Nutzer wird ein nicht-exklusives, nicht übertragbares, widerrufliches Nutzungsrecht eingeräumt.\n\n'
                  '4.3 Jegliche kommerzielle Nutzung, Vervielfältigung oder Weitergabe ist ohne ausdrückliche schriftliche Genehmigung untersagt.',
            ),

            _buildSection(
              context,
              '5. Preisvergleiche und Inhalte',
              '5.1 Nutzer dürfen Preisvergleiche und Inhalte nur abgeben, wenn sie sich persönlich über deren Korrektheit überzeugt haben.\n\n'
                  '5.2 Preisvergleiche müssen wahrheitsgemäß und sachlich sein.\n\n'
                  '5.3 Es ist untersagt, beleidigende, verleumderische, rechtswidrige oder jugendgefährdende Inhalte gemeinsam mit dem Preisvergleich zu veröffentlichen.\n\n'
                  '5.4 Preisvergleiche dürfen keine personenbezogenen Daten Dritter enthalten, außer diese sind für den Preisvergleichea wesentlich und der Betroffene hat eingewilligt.\n\n'
                  '5.5 Der Betreiber behält sich das Recht vor, Inhalte ohne Angabe von Gründen zu entfernen.',
            ),

            _buildSection(
              context,
              '6. Verantwortung der Nutzer',
              '6.1 Nutzer sind für die von ihnen veröffentlichten Inhalte verantwortlich.\n\n'
                  '6.2 Nutzer haften für Schäden, die durch rechtswidrige Inhalte entstehen.\n\n'
                  '6.3 Nutzer dürfen die App nicht missbräuchlich nutzen oder versuchen, das System zu manipulieren.\n\n'
                  '6.4 Die Verbreitung von Spam, Werbung oder Kettenbriefen ist untersagt.',
            ),

            _buildSection(
              context,
              '7. Haftungsausschluss',
              '7.1 Die App wird ohne Gewährleistung bereitgestellt. Der Betreiber übernimmt keine Haftung für die Richtigkeit, Vollständigkeit oder Aktualität der Inhalte.\n\n'
                  '7.2 Der Betreiber haftet nicht für Schäden, die durch die Nutzung oder Nichtnutzung der App entstehen, außer bei Vorsatz oder grober Fahrlässigkeit.\n\n'
                  '7.3 Der Betreiber haftet nicht für Inhalte Dritter, die über die App zugänglich sind.',
            ),

            _buildSection(
              context,
              '8. Verfügbarkeit',
              'Der Betreiber bemüht sich um eine möglichst hohe Verfügbarkeit der App. Wartungsarbeiten, technische Probleme oder höhere Gewalt können jedoch zu Unterbrechungen führen. Der Betreiber haftet nicht für solche Unterbrechungen.',
            ),

            _buildSection(
              context,
              '9. Änderung der AGB',
              'Der Betreiber behält sich das Recht vor, diese AGB jederzeit zu ändern. Die geänderten AGB werden den Nutzern spätestens 14 Tage vor ihrem Inkrafttreten mitgeteilt. Widerspricht der Nutzer nicht innerhalb dieser Frist, gelten die geänderten AGB als angenommen.',
            ),

            _buildSection(
              context,
              '10. Kündigung',
              '10.1 Der Nutzer kann sein Konto jederzeit löschen.\n\n'
                  '10.2 Der Betreiber kann das Nutzerkonto bei Verstoß gegen diese AGB oder bei rechtswidrigem Verhalten kündigen.\n\n'
                  '10.3 Im Falle einer Kündigung werden die Nutzerdaten gemäß der Datenschutzerklärung gelöscht.',
            ),

            _buildSection(
              context,
              '11. Preisvergleichslöschung aus rechtlichen Gründen',
              'Preisvergleiche können aus folgenden Gründen gelöscht werden:\n\n'
                  '• Rechtliche Verurteilung wegen Verleumdung\n'
                  '• Gerichtliche Anordnung\n'
                  '• Offensichtliche Falschinformationen mit nachweisbarem Schaden\n'
                  '• Persönlichkeitsrechtsverletzungen\n'
                  '• Beleidigungen oder üble Nachreden\n\n'
                  'Negative Preisvergleiche allein begründen keinen Anspruch auf Löschung. Die Meinungsfreiheit hat Vorrang vor dem Recht auf ein positives Image.\n\n'
                  'Preisvergleiche werden nur gelöscht wenn konkrete rechtliche Verstöße nachgewiesen sind.',
            ),

            _buildSection(
              context,
              '12. Anwendbares Recht',
              'Diese AGB unterliegen dem Recht der Bundesrepublik Österreich. Bei Verbrauchern gilt diese Rechtswahl nur insoweit, als nicht der gewährte Schutz durch zwingende Bestimmungen des Staates, in dem der Verbraucher seinen gewöhnlichen Aufenthalt hat, entzogen wird.',
            ),

            _buildSection(
              context,
              '13. Salvatorische Klausel',
              'Sollten einzelne Bestimmungen dieser AGB unwirksam sein oder werden, berührt dies die Wirksamkeit der übrigen Bestimmungen nicht. Die unwirksame Bestimmung ist durch eine wirksame Regelung zu ersetzen, die dem wirtschaftlichen Zweck der unwirksamen Bestimmung möglichst nahekommt.',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
          ],
        ),
      ),
    );
  }

  Widget _buildImprint(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Impressum'), 
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Impressum',
              style: TextStyle(
                fontSize: AppTypography.headline2, // ✅ THEME TYPOGRAFIE
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // ✅ THEME FARBE
              ),
            ),
            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND

            _buildSection(
              context,
              'Angaben gemäß § 5 TMG',
              'Boban Milanovic\n'
                  'Hormayrstr. 12\n'
                  '6020 Innsbruck\n'
                  'Österreich',
            ),

            _buildSection(
              context,
              'Kontakt',
              'Telefon: +43 681 84973149\n'
                  'E-Mail: boban.milanovic+preistracking@gmail.com',
            ),

            _buildSection(
              context,
              'Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV',
              'Boban Milanovic\n'
                  'Hormayrstr. 12\n'
                  '6020 Innsbruck\n'
                  'Österreich',
            ),

            _buildSection(
              context,
              'Haftung für Inhalte',
              'Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.\n\n'
                  'Verpflichtungen zur Entfernung oder Sperrung der Nutzung von Informationen nach den allgemeinen Gesetzen bleiben hiervon unberührt. Eine diesbezügliche Haftung ist jedoch erst ab dem Zeitpunkt der Kenntnis einer konkreten Rechtsverletzung möglich. Bei Bekanntwerden von entsprechenden Rechtsverletzungen werden wir diese Inhalte umgehend entfernen.',
            ),

            _buildSection(
              context,
              'Haftung für Links',
              'Unser Angebot enthält Links zu externen Websites Dritter, auf deren Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber der Seiten verantwortlich. Die verlinkten Seiten wurden zum Zeitpunkt der Verlinkung auf mögliche Rechtsverstöße überprüft. Rechtswidrige Inhalte waren zum Zeitpunkt der Verlinkung nicht erkennbar.\n\n'
                  'Eine permanente inhaltliche Kontrolle der verlinkten Seiten ist jedoch ohne konkrete Anhaltspunkte einer Rechtsverletzung nicht zumutbar. Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Links umgehend entfernen.',
            ),

            _buildSection(
              context,
              'Urheberrecht',
              'Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers. Downloads und Kopien dieser Seite sind nur für den privaten, nicht kommerziellen Gebrauch gestattet.\n\n'
                  'Soweit die Inhalte auf dieser Seite nicht vom Betreiber erstellt wurden, werden die Urheberrechte Dritter beachtet. Insbesondere werden Inhalte Dritter als solche gekennzeichnet. Sollten Sie trotzdem auf eine Urheberrechtsverletzung aufmerksam werden, bitten wir um einen entsprechenden Hinweis. Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Inhalte umgehend entfernen.',
            ),

            SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dokument nicht gefunden'),
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: Center(
        child: Text(
          'Das angeforderte Dokument wurde nicht gefunden.',
          style: TextStyle(
            fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
            color: AppColors.textPrimary, // ✅ THEME FARBE
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
            fontWeight: FontWeight.bold,
            color: AppColors.primary, // ✅ THEME FARBE
          ),
        ),
        SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
        Text(
          content, 
          style: TextStyle(
            fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
            height: 1.6,
            color: AppColors.textPrimary, // ✅ THEME FARBE
          ),
        ),
        SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
      ],
    );
  }
}