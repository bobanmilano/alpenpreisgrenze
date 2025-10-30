import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/utils/string_utils.dart';
import '../models/price_entry.dart';
import '../screens/add_price_screen.dart';
import 'price_content.dart';
import '../services/firebase_service.dart';

class PriceCard extends StatefulWidget {
  final String title; // 'Österreich' oder 'Deutschland'
  final String targetCountry;
  final String barcode;
  final String userId;
  final Stream<List<PriceEntry>> userPriceStream;
  final Stream<PriceEntry?> cheapestOtherPriceStream;
  final Function(VoidCallback fn) onNavigate;
  final Stream<List<PriceEntry>> allPricesStream;
  final FirebaseService firebaseService;
  final ValueChanged<PriceEntry?> onPriceChanged;

  const PriceCard({
    Key? key,
    required this.title,
    required this.targetCountry,
    required this.barcode,
    required this.userId,
    required this.userPriceStream,
    required this.cheapestOtherPriceStream,
    required this.onNavigate,
    required this.allPricesStream,
    required this.firebaseService,
    required this.onPriceChanged,
  }) : super(key: key);

  @override
  _PriceCardState createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentIndex;

  @override
  bool get wantKeepAlive => true; // Behalte den Zustand bei

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentIndex = ValueNotifier(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wichtig für AutomaticKeepAliveClientMixin
    final isAT = widget.title == 'Österreich';
    return Expanded(
      child: Card(
        margin: EdgeInsets.all(4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAT)
                _buildATPriceSection(context)
              else
                _buildDEPriceSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildATPriceSection(BuildContext context) {
    return StreamBuilder<List<PriceEntry>>(
      stream: widget.firebaseService.getAllPricesForCountryAndBarcode(
        widget.targetCountry,
        widget.barcode,
      ),
      builder: (context, allSnapshot) {
        if (allSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (allSnapshot.hasError) {
          return Text('Fehler: ${allSnapshot.error}');
        }

        final allPrices = allSnapshot.data ?? [];
        final now = DateTime.now();
        final oneMonthAgo = now.subtract(Duration(days: 365));

        final countryPrices = allPrices
            .where(
              (price) =>
                  price.country == widget.targetCountry &&
                  price.timestamp.isAfter(oneMonthAgo),
            )
            .toList();

        countryPrices.sort((a, b) => b.price.compareTo(a.price));

        if (countryPrices.isEmpty) {
          return _buildNoPriceWidget(context);
        }

        return _buildPriceSlider(countryPrices, context);
      },
    );
  }

  Widget _buildDEPriceSection(BuildContext context) {
    return StreamBuilder<List<PriceEntry>>(
      stream: widget.firebaseService.getAllPricesForCountryAndBarcode(
        widget.targetCountry,
        widget.barcode,
      ),
      builder: (context, allSnapshot) {
        if (allSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (allSnapshot.hasError) {
          return Text('Fehler: ${allSnapshot.error}');
        }

        final allPrices = allSnapshot.data ?? [];
        final now = DateTime.now();
        final oneMonthAgo = now.subtract(Duration(days: 365));

        final countryPrices = allPrices
            .where(
              (price) =>
                  price.country == widget.targetCountry &&
                  price.timestamp.isAfter(oneMonthAgo),
            )
            .toList();

        countryPrices.sort((a, b) => a.price.compareTo(b.price));

        if (countryPrices.isEmpty) {
          return _buildNoPriceWidget(context);
        }

        return _buildPriceSlider(countryPrices, context);
      },
    );
  }

  String _getDisplayString(String? input, String attributeName) {
    if (input == null)
      return '${attributeName} N/A'; // oder wie auch immer du mit null umgehst
    return toProperCase(input);
  }

  Widget _buildPriceSlider(List<PriceEntry> prices, BuildContext context) {
    return Column(
      children: [
        // Fahne und Stadtname oben
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              widget.targetCountry == 'Österreich'
                  ? 'assets/logos/at-fahne.png'
                  : 'assets/logos/de-fahne.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.flag, size: 32);
              },
            ),
            SizedBox(width: 8),
            // Dynamischer Stadtname mit ValueListenableBuilder
            ValueListenableBuilder<int>(
              valueListenable: _currentIndex,
              builder: (context, currentIndex, _) {
                return Text(
                  _getDisplayString(prices[currentIndex].city, "Stadt"), // Falls city null ist
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 6),
        // Container mit PageView und Pfeilen als Stack
        Container(
          height: 220,
          child: Stack(
            alignment: Alignment.center, // Zentriert den PageView
            children: [
              // PageView im Hintergrund
              PageView.builder(
                controller: _pageController,
                itemCount: prices.length,
                onPageChanged: (index) {
                  _currentIndex.value = index;
                  final selectedPrice = prices[index];
                  print('Neuer Preis ausgewählt: ${selectedPrice.price}');
                  widget.onPriceChanged(selectedPrice);
                },
                itemBuilder: (context, index) {
                  final price = prices[index];
                  return Center(child: PriceContent(priceEntry: price));
                },
              ),
              // Pfeile über dem PageView
              // Linker Pfeil - sehr nah am linken Rand
              Align(
                alignment: Alignment(
                  -1,
                  0,
                ), // x = -0.95, sehr nah am linken Rand
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentIndex,
                  builder: (context, currentIndex, _) {
                    return IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: currentIndex > 0
                          ? () {
                              _currentIndex.value--;
                              _pageController.animateToPage(
                                _currentIndex.value,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      color: currentIndex > 0
                          ? Theme.of(context).iconTheme.color
                          : Colors.grey.withOpacity(0),
                      padding: EdgeInsets.all(2), // Minimaler Abstand
                      // Optional: Hintergrund für den Button, um ihn besser sichtbar zu machen
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        shape: CircleBorder(),
                      ),
                    );
                  },
                ),
              ),
              // Rechter Pfeil - sehr nah am rechten Rand
              Align(
                alignment: Alignment(
                  1,
                  0,
                ), // x = 0.95, sehr nah am rechten Rand
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentIndex,
                  builder: (context, currentIndex, _) {
                    return IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: currentIndex < prices.length - 1
                          ? () {
                              _currentIndex.value++;
                              _pageController.animateToPage(
                                _currentIndex.value,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      color: currentIndex < prices.length - 1
                          ? Theme.of(context).iconTheme.color
                          : Colors.grey.withOpacity(0),
                      padding: EdgeInsets.all(2), // Minimaler Abstand
                      // Optional: Hintergrund für den Button, um ihn besser sichtbar zu machen
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        shape: CircleBorder(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Keine Pfeile mehr am unteren Ende
      ],
    );
  }

  Widget _buildNoPriceWidget(BuildContext context) {
    return SizedBox(
      height: 250, // Feste Höhe für die Card
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Verteilt die Kinder
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fahne oben links
          Row(
            children: [
              Image.asset(
                widget.targetCountry == 'Österreich'
                    ? 'assets/logos/at-fahne.png'
                    : 'assets/logos/de-fahne.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.flag, size: 32);
                },
              ),
            ],
          ),
          // Vertikal und horizontal zentrierter Text
          Expanded(
            child: Center(
              child: Text(
                'Kein Preis eingetragen',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          // Button am unteren Rand
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton(
              onPressed: () {
                widget.onNavigate(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPriceScreen(
                        barcode: widget.barcode,
                        targetCountry: widget.targetCountry,
                      ),
                    ),
                  );
                });
              },
              child: Text('Preis hinzufügen',  textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}
