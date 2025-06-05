import 'dart:io';
import 'package:ansicolor/ansicolor.dart';

void clearScreen() {
  print(Process.runSync("clear", [], runInShell: true).stdout); //Clean
}

enum Transportmittel { auto, zug, fahrrad, bus, zuFuss }

// Hilfsfunktion für farbige Balken
String erstelleFarbigenBalken(int laenge, AnsiPen pen) {
  const int maxBlocks = 40;
  if (laenge > maxBlocks) laenge = maxBlocks;
  return pen('█' * laenge);
}

// Farbe je nach Entfernung wählen
AnsiPen farbeFuerDistanz(int distanz) {
  if (distanz > 200) return AnsiPen()..red();
  if (distanz > 100) return AnsiPen()..yellow();
  return AnsiPen()..green();
}

// Hilfsfunktion: Tabelle drucken mit festen Spalten
void druckeTabelle(List<List<String>> daten, List<int> spaltenBreiten) {
  String zeilenTrenner() =>
      '+' + spaltenBreiten.map((b) => '-' * b).join('+') + '+';

  print(zeilenTrenner());

  // Überschrift fett und invertiert (weißer Text auf schwarzem Grund)
  var penBold = AnsiPen()..white(bg: true);
  List<String> header = daten[0];
  String headerText = '|';
  for (int j = 0; j < spaltenBreiten.length; j++) {
    headerText +=
        ' ' + penBold(header[j].padRight(spaltenBreiten[j] - 1)) + '|';
  }
  print(headerText);
  print(zeilenTrenner());

  // Datenzeilen ohne Trenner dazwischen, nur am Ende
  for (int i = 1; i < daten.length; i++) {
    List<String> zeile = daten[i];
    String zeileText = '|';
    for (int j = 0; j < spaltenBreiten.length; j++) {
      String zellenInhalt = j < zeile.length ? zeile[j] : '';
      zeileText += ' ' + zellenInhalt.padRight(spaltenBreiten[j] - 1) + '|';
    }
    print(zeileText);
  }
  print(zeilenTrenner());
}

void main() {
  Map<String, int> reiseroute = {
    "Max": 120,
    "Peter": 90,
    "Anna": 270,
    "Lena": 180,
  };

  // Tabelle Transportmittel vorbereiten
  List<List<String>> transportDaten = [
    ['Nr.', 'Transportmittel']
  ];
  for (int i = 0; i < Transportmittel.values.length; i++) {
    String originalName = Transportmittel.values[i].name;
    String name = originalName == 'zuFuss'
        ? 'zu Fuß'
        : originalName[0].toUpperCase() +
            originalName.substring(
                1); //Großschreibung der Anfangsbuchstaben in der Tabelle
    transportDaten.add([(i + 1).toString(), name]);
  }

  clearScreen(); //clean Screen vor Print
  print('--- Transportmittel Auswahl ---');
  druckeTabelle(transportDaten, [5, 20]);

  int? auswahl;
  do {
    stdout.write(
      'Bitte wähle dein Transportmittel (1-${Transportmittel.values.length}): ',
    );
    String? eingabe = stdin.readLineSync();
    auswahl = eingabe != null ? int.tryParse(eingabe) : null;
  } while (auswahl == null ||
      auswahl < 1 ||
      auswahl > Transportmittel.values.length);

  Transportmittel mittel = Transportmittel.values[auswahl - 1];
  String mittelName = mittel.name == 'zuFuss' ? 'zu Fuß' : mittel.name;

  // Standardgeschwindigkeit je Transportmittel
  int defaultGeschwindigkeit;
  switch (mittel) {
    case Transportmittel.auto:
      defaultGeschwindigkeit = 90;
      break;
    case Transportmittel.zug:
      defaultGeschwindigkeit = 120;
      break;
    case Transportmittel.fahrrad:
      defaultGeschwindigkeit = 20;
      break;
    case Transportmittel.bus:
      defaultGeschwindigkeit = 60;
      break;
    case Transportmittel.zuFuss:
      defaultGeschwindigkeit = 5;
      break;
  }

  stdout.write(
    "Gib eine Geschwindigkeit in km/h ein (oder Enter für Standard $defaultGeschwindigkeit km/h): ",
  );
  String? geschwindigkeitInput = stdin.readLineSync();

  int geschwindigkeit =
      (geschwindigkeitInput == null || geschwindigkeitInput.isEmpty)
          ? defaultGeschwindigkeit
          : (int.tryParse(geschwindigkeitInput) ?? defaultGeschwindigkeit);

  // Tabelle Freunde vorbereiten
  List<String> freunde = reiseroute.keys.toList();
  List<List<String>> freundeDaten = [
    ['Nr.', 'Name', 'Entfernung (km)']
  ];
  for (int i = 0; i < freunde.length; i++) {
    freundeDaten.add(
        [(i + 1).toString(), freunde[i], reiseroute[freunde[i]]!.toString()]);
  }

  clearScreen();
  print('\n--- Freunde Auswahl ---');
  druckeTabelle(freundeDaten, [5, 15, 15]);

  List<int> ausgewaehlteIndizes = [];
  do {
    stdout.write(
      'Bitte wähle deine Freunde (mehrere mit Komma getrennt, z.B. 1,3): ',
    );
    String? freundeEingabe = stdin.readLineSync();
    if (freundeEingabe != null && freundeEingabe.isNotEmpty) {
      List<String> parts = freundeEingabe.split(',');
      bool alleGueltig = true;
      Set<int> tempIndizesSet = {};
      for (var part in parts) {
        int? index = int.tryParse(part.trim());
        if (index == null || index < 1 || index > freunde.length) {
          alleGueltig = false;
          break;
        }
        tempIndizesSet.add(index - 1); // Duplikate verhindern
      }
      if (alleGueltig && tempIndizesSet.isNotEmpty) {
        ausgewaehlteIndizes = tempIndizesSet.toList();
      } else {
        ausgewaehlteIndizes = [];
      }
    }
  } while (ausgewaehlteIndizes.isEmpty);

  // Ausgabe nach Entfernung sortieren
  ausgewaehlteIndizes.sort(
      (a, b) => reiseroute[freunde[a]]!.compareTo(reiseroute[freunde[b]]!));

  // Ergebnisse anzeigen (mit Balken wie vorher)
  double gesamtZeit = 0;
  int gesamtKm = 0;

  clearScreen(); //clean Screen vor Print
  print("\n--- Ergebnisse ---");

  int maxDistanz = 0;
  for (var idx in ausgewaehlteIndizes) {
    int dist = reiseroute[freunde[idx]]!;
    if (dist > maxDistanz) maxDistanz = dist;
  }

  for (var idx in ausgewaehlteIndizes) {
    String name = freunde[idx];
    int distanz = reiseroute[name]!;
    double zeit = distanz / geschwindigkeit;
    gesamtZeit += zeit;
    gesamtKm += distanz;

    int stunden = zeit.floor();
    int minuten = ((zeit - stunden) * 60).round();

    int balkenLaenge = ((distanz / maxDistanz) * 40).round();
    AnsiPen pen = farbeFuerDistanz(distanz);
    String balken = erstelleFarbigenBalken(balkenLaenge, pen);

    print(
      "$name: Entfernung = $distanz km $balken Fahrzeit = ${stunden} h ${minuten} min", //Zeitausgabe in Stunden und Minuten
    );
  }

  int gesamtStunden = gesamtZeit.floor();
  int gesamtMinuten = ((gesamtZeit - gesamtStunden) * 60).round();

  print("\nGesamtdistanz: $gesamtKm km");
  print("Gesamtfahrzeit: ${gesamtStunden} h ${gesamtMinuten} min");

  print(
      "Transportmittel: ${mittelName[0].toUpperCase()}${mittelName.substring(1)}");

  // Abschiedsgruß
  var gruen = AnsiPen()..green(bold: true);
  var white = AnsiPen()..white(bold: true);
  print('\n' + gruen('Gute Reise! 🌍'));
  print(white('Und viel Spaß beim Besuchen deiner Freunde!'));
}
