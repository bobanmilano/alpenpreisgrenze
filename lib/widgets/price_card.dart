import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/utils/string_utils.dart';
import '../models/price_entry.dart';
import '../screens/add_price_screen.dart';
import 'price_content.dart';
import '../services/firebase_service.dart';

class PriceCard extends StatefulWidget {
  final String title;
  final String targetCountry;
  final String barcode;
  final String userId;
  final Stream<List<PriceEntry>> userPriceStream;
  final Stream<PriceEntry?> cheapestOtherPriceStream;
  final Function(VoidCallback fn) onNavigate;
  final Stream<List<PriceEntry>> allPricesStream;
  final FirebaseService firebaseService;
  final ValueChanged<PriceEntry?> onPriceChanged;
  final List<PriceEntry>? preloadedPrices; // Optional: bereits geladene Preise

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
    this.preloadedPrices,
  }) : super(key: key);

  @override
  _PriceCardState createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentIndex;
  List<PriceEntry> _filteredPrices = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentIndex = ValueNotifier(0);
    print('[PriceCard] initState ausgeführt für ${widget.title}');
    
    // Initialisiere die Preise, wenn welche vorliegen
    if (widget.preloadedPrices != null) {
      _updatePrices(widget.preloadedPrices!);
    }
  }

  void _updatePrices(List<PriceEntry> prices) {
    print('[PriceCard] _updatePrices aufgerufen für ${widget.title} mit ${prices.length} Preisen');
    
    // Filtere und sortiere die Preise
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(Duration(days: 365));

    _filteredPrices = prices
        .where((price) => price.country == widget.targetCountry)
        .where((price) => price.timestamp.isAfter(oneMonthAgo))
        .toList();

    // Sortiere nach Land
    if (widget.targetCountry == 'Österreich') {
      _filteredPrices.sort((a, b) => b.price.compareTo(a.price)); // Höchster zuerst
    } else {
      _filteredPrices.sort((a, b) => a.price.compareTo(b.price)); // Niedrigster zuerst
    }

    print('[PriceCard] Gefilterte und sortierte Preise für ${widget.title}: ${_filteredPrices.length}');
    for (int i = 0; i < _filteredPrices.length; i++) {
      print('[PriceCard] ${widget.title} Preis $i: ${_filteredPrices[i].price} von ${_filteredPrices[i].displayStore}');
    }

    // Setze den ersten Preis, wenn verfügbar
    if (_filteredPrices.isNotEmpty && _currentIndex.value >= _filteredPrices.length) {
      _currentIndex.value = 0;
    } else if (_filteredPrices.isNotEmpty && _currentIndex.value < _filteredPrices.length) {
      widget.onPriceChanged(_filteredPrices[_currentIndex.value]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    print('[PriceCard] build aufgerufen für ${widget.title}');
    print('[PriceCard] preloadedPrices: ${widget.preloadedPrices?.length}');
    print('[PriceCard] filteredPrices: ${_filteredPrices.length}');

    final isAT = widget.title == 'Österreich';
    
    return Card(
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
    );
  }

  Widget _buildATPriceSection(BuildContext context) {
    if (widget.preloadedPrices != null) {
      // Verwende vorab geladene Preise
      _updatePrices(widget.preloadedPrices!);
      return _buildPriceSection(context);
    } else {
      // Verwende Stream, falls keine vorab geladenen Preise vorhanden sind
      return StreamBuilder<List<PriceEntry>>(
        stream: widget.allPricesStream,
        builder: (context, snapshot) {
          print('[PriceCard] StreamBuilder für AT - ConnectionState: ${snapshot.connectionState}');
          print('[PriceCard] StreamBuilder für AT - HasData: ${snapshot.hasData}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('[PriceCard] Warte auf Preisdaten für Österreich...');
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('[PriceCard] Fehler beim Laden der Preisdaten für Österreich: ${snapshot.error}');
            return Text('Fehler: ${snapshot.error}');
          }

          final allPrices = snapshot.data ?? [];
          _updatePrices(allPrices);
          
          return _buildPriceSection(context);
        },
      );
    }
  }

  Widget _buildDEPriceSection(BuildContext context) {
    if (widget.preloadedPrices != null) {
      // Verwende vorab geladene Preise
      _updatePrices(widget.preloadedPrices!);
      return _buildPriceSection(context);
    } else {
      // Verwende Stream, falls keine vorab geladenen Preise vorhanden sind
      return StreamBuilder<List<PriceEntry>>(
        stream: widget.allPricesStream,
        builder: (context, snapshot) {
          print('[PriceCard] StreamBuilder für DE - ConnectionState: ${snapshot.connectionState}');
          print('[PriceCard] StreamBuilder für DE - HasData: ${snapshot.hasData}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('[PriceCard] Warte auf Preisdaten für Deutschland...');
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('[PriceCard] Fehler beim Laden der Preisdaten für Deutschland: ${snapshot.error}');
            return Text('Fehler: ${snapshot.error}');
          }

          final allPrices = snapshot.data ?? [];
          _updatePrices(allPrices);
          
          return _buildPriceSection(context);
        },
      );
    }
  }

  Widget _buildPriceSection(BuildContext context) {
    print('[PriceCard] _buildPriceSection für ${widget.title} - filteredPrices: ${_filteredPrices.length}');

    if (_filteredPrices.isEmpty) {
      print('[PriceCard] Keine Preise für ${widget.title} gefunden');
      return _buildNoPriceWidget(context);
    }

    return _buildPriceSlider(context);
  }

  String _getDisplayString(String? input, String attributeName) {
    if (input == null) {
      print('[PriceCard] $attributeName ist null');
      return '${attributeName} N/A';
    }
    return toProperCase(input);
  }

  Widget _buildPriceSlider(BuildContext context) {
    print('[PriceCard] _buildPriceSlider aufgerufen - Preise: ${_filteredPrices.length}');

    return Column(
      children: [
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
                print('[PriceCard] Fehler beim Laden des Flaggenbildes: $error');
                return Icon(Icons.flag, size: 32);
              },
            ),
            SizedBox(width: 8),
            ValueListenableBuilder<int>(
              valueListenable: _currentIndex,
              builder: (context, currentIndex, _) {
                if (currentIndex < _filteredPrices.length) {
                  print('[PriceCard] Aktueller Index im PriceSlider: $currentIndex');
                  return Text(
                    _getDisplayString(_filteredPrices[currentIndex].city, "Stadt"),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return Text('');
              },
            ),
          ],
        ),
        SizedBox(height: 6),
        Container(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _filteredPrices.length,
                onPageChanged: (index) {
                  print('[PriceCard] Seite gewechselt zu Index: $index');
                  _currentIndex.value = index;
                  if (index < _filteredPrices.length) {
                    final selectedPrice = _filteredPrices[index];
                    print('[PriceCard] Neuer Preis ausgewählt: ${selectedPrice.price}');
                    widget.onPriceChanged(selectedPrice);
                  }
                },
                itemBuilder: (context, index) {
                  if (index < _filteredPrices.length) {
                    final price = _filteredPrices[index];
                    print('[PriceCard] Rendering PriceContent für Preis: ${price.price}');
                    return Center(child: PriceContent(priceEntry: price));
                  }
                  return Center(child: Text('Kein Preis'));
                },
              ),
              Align(
                alignment: Alignment(-1, 0),
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentIndex,
                  builder: (context, currentIndex, _) {
                    return IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: currentIndex > 0
                          ? () {
                              print('[PriceCard] Pfeil nach links gedrückt');
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
                      padding: EdgeInsets.all(2),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        shape: CircleBorder(),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment(1, 0),
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentIndex,
                  builder: (context, currentIndex, _) {
                    return IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: currentIndex < _filteredPrices.length - 1
                          ? () {
                              print('[PriceCard] Pfeil nach rechts gedrückt');
                              _currentIndex.value++;
                              _pageController.animateToPage(
                                _currentIndex.value,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      color: currentIndex < _filteredPrices.length - 1
                          ? Theme.of(context).iconTheme.color
                          : Colors.grey.withOpacity(0),
                      padding: EdgeInsets.all(2),
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
      ],
    );
  }

  Widget _buildNoPriceWidget(BuildContext context) {
    print('[PriceCard] _buildNoPriceWidget aufgerufen für ${widget.title}');
    return SizedBox(
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                widget.targetCountry == 'Österreich'
                    ? 'assets/logos/at-fahne.png'
                    : 'assets/logos/de-fahne.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  print('[PriceCard] Fehler beim Laden des Flaggenbildes: $error');
                  return Icon(Icons.flag, size: 32);
                },
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                'Kein Preis eingetragen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton(
              onPressed: () {
                print('[PriceCard] Preishinzufügen-Button gedrückt für ${widget.title}');
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
              child: Text(
                'Preis hinzufügen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}