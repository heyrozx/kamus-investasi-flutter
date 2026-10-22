import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final Uri _url = Uri.parse('https://nexadream.id');

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(65, 83, 181, 1),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Image.asset('assets/images/feedback.png')),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Hubungi Kami',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'Apabila ada kata atau definisi yang kurang tepat, silahkan hubungi kami. Kontribusi anda sangat membantu proses pengembangan aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  // fontSize: 30,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 44),
              width: double.infinity,
              child: FilledButton(
                  onPressed: () => _launchUrl(),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text(
                    'HUBUNGI KAMI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
            ),
            SizedBox(
              height: 6,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 44),
              width: double.infinity,
              child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'KEMBALI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
