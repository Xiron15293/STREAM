import 'package:flutter/material.dart';

class StreamIconEntry {
  final String key;
  final String label;
  final IconData icon;
  const StreamIconEntry(this.key, this.label, this.icon);
}

class StreamIconGroup {
  final String name;
  final List<StreamIconEntry> entries;
  const StreamIconGroup(this.name, this.entries);
}

class StreamIconLibrary {
  static const String defaultCategoryIcon = 'tag';
  static const String defaultAccountIcon = 'wallet';
  static const IconData fallbackIcon = Icons.help_outline;

  // ──────────────────────────────────────────────────────────────
  // Icon data (iconKey → IconData)
  // ──────────────────────────────────────────────────────────────

  static final Map<String, IconData> _iconMap = {
    // ── Veicoli ──
    'car': Icons.directions_car_outlined,
    'motorcycle': Icons.motorcycle_outlined,
    'bicycle': Icons.directions_bike_outlined,
    'scooter': Icons.electric_scooter_outlined,
    'bus': Icons.directions_bus_outlined,
    'train': Icons.train_outlined,
    'airplane': Icons.flight_outlined,
    'boat': Icons.directions_boat_outlined,
    'taxi': Icons.local_taxi_outlined,
    'truck': Icons.local_shipping_outlined,
    'walk': Icons.directions_walk_outlined,
    'hiking': Icons.hiking_outlined,
    'car-simple': Icons.time_to_leave_outlined,
    'gas-pump': Icons.local_gas_station_outlined,
    'park': Icons.local_parking_outlined,
    'bird': Icons.two_wheeler_outlined, // motocicletta

    // ── Casa ──
    'house': Icons.home_outlined,
    'building': Icons.business_outlined,
    'house-line': Icons.home_max_outlined,
    'garage': Icons.garage_outlined,
    'door': Icons.door_sliding_outlined,
    'window': Icons.window_outlined,
    'sofa': Icons.weekend_outlined,
    'chair': Icons.chair_outlined,
    'bed': Icons.bed_outlined,
    'lamp': Icons.emoji_objects_outlined,
    'lightbulb': Icons.lightbulb_outlined,
    'fan': Icons.air_outlined,
    'key': Icons.key_outlined,
    'lock': Icons.lock_outlined,
    'shower': Icons.shower_outlined,
    'bathtub': Icons.bathtub_outlined,
    'toolbox': Icons.handyman_outlined,
    'wrench': Icons.build_outlined,
    'ladder': Icons.height_outlined,

    // ── Cibo & Cucina ──
    'shopping-cart': Icons.shopping_cart_outlined,
    'restaurant': Icons.restaurant_outlined,
    'coffee': Icons.coffee_outlined,
    'cake': Icons.cake_outlined,
    'pizza': Icons.local_pizza_outlined,
    'hamburger': Icons.lunch_dining_outlined,
    'beer': Icons.sports_bar_outlined,
    'food': Icons.ramen_dining_outlined,
    'ice-cream': Icons.icecream_outlined,
    'cookie': Icons.cookie_outlined,
    'wine': Icons.wine_bar_outlined,
    'bread': Icons.bakery_dining_outlined,
    'apple': Icons.apple_outlined,
    'kebab': Icons.kebab_dining_outlined,
    'tea': Icons.emoji_food_beverage_outlined,
    'fastfood': Icons.fastfood_outlined,
    'egg': Icons.egg_outlined,
    'brunch': Icons.brunch_dining_outlined,
    'liquor': Icons.liquor_outlined,
    'takeout': Icons.dinner_dining_outlined,

    // ── Shopping ──
    'shopping-bag': Icons.shopping_bag_outlined,
    'shopping-cart-2': Icons.add_shopping_cart_outlined,
    'tag': Icons.sell_outlined,
    'hanger': Icons.checkroom_outlined,
    'gift': Icons.card_giftcard_outlined,
    'bag': Icons.backpack_outlined,
    'storefront': Icons.storefront_outlined,
    'barcode': Icons.qr_code_scanner_outlined,
    'tote': Icons.shopping_cart_outlined,
    'handbag': Icons.shopping_bag_outlined,
    'shoe': Icons.directions_walk_outlined,
    'diamond': Icons.diamond_outlined,

    // ── Finanza & Entrate ──
    'money': Icons.money_outlined,
    'bank': Icons.account_balance_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'cash': Icons.money_rounded,
    'coins': Icons.payments_outlined,
    'hand-coins': Icons.paid_outlined,
    'piggy-bank': Icons.savings_outlined,
    'receipt': Icons.receipt_outlined,
    'receipt-x': Icons.receipt_long_outlined,
    'file-text': Icons.description_outlined,
    'calculator': Icons.calculate_outlined,
    'percentage': Icons.percent_outlined,
    'currency-dollar': Icons.attach_money_outlined,
    'currency-eur': Icons.euro_outlined,
    'currency-gbp': Icons.money_off_outlined,
    'trend-up': Icons.trending_up_outlined,
    'trend-down': Icons.trending_down_outlined,
    'chart-bar': Icons.bar_chart_outlined,
    'chart-pie': Icons.pie_chart,
    'chart-line': Icons.show_chart_outlined,

    // ── Lavoro & Istruzione ──
    'briefcase': Icons.business_center_outlined,
    'suitcase': Icons.work_outlined,
    'laptop': Icons.computer_outlined,
    'desktop': Icons.desktop_windows_outlined,
    'backpack': Icons.backpack_outlined,
    'clipboard': Icons.assignment_outlined,
    'paperclip': Icons.attach_file_outlined,
    'envelope': Icons.mail_outlined,
    'chat': Icons.chat_outlined,
    'users': Icons.group_outlined,
    'user': Icons.person_outlined,
    'user-circle': Icons.account_circle_outlined,
    'badge': Icons.badge_outlined,
    'certificate': Icons.workspace_premium_outlined,
    'book-open': Icons.auto_stories_outlined,
    'graduation-cap': Icons.school_outlined,
    'pencil': Icons.edit_outlined,
    'pen': Icons.create_outlined,
    'globe': Icons.language_outlined,
    'atom': Icons.science_outlined,
    'flask': Icons.biotech_outlined,
    'card': Icons.credit_card_outlined,

    // ── Tecnologia ──
    'smartphone': Icons.phone_android_outlined,
    'tablet': Icons.tablet_android_outlined,
    'computer': Icons.desktop_windows_outlined,
    'monitor': Icons.monitor_outlined,
    'printer': Icons.print_outlined,
    'wifi': Icons.wifi_outlined,
    'hard-drive': Icons.storage_outlined,
    'sim-card': Icons.sim_card_outlined,
    'plug': Icons.power_outlined,
    'battery': Icons.battery_charging_full_outlined,
    'cable': Icons.usb_outlined,
    'database': Icons.dns_outlined,
    'memory': Icons.memory_outlined,
    'security': Icons.security_outlined,

    // ── Tempo Libero ──
    'game-controller': Icons.sports_esports_outlined,
    'film': Icons.movie_outlined,
    'movie': Icons.theaters_outlined,
    'music-note': Icons.music_note_outlined,
    'music-notes': Icons.queue_music_outlined,
    'headphones': Icons.headphones_outlined,
    'microphone': Icons.mic_outlined,
    'ticket': Icons.confirmation_number_outlined,
    'popcorn': Icons.camera_indoor_outlined,
    'confetti': Icons.celebration_outlined,
    'dice': Icons.casino_outlined,
    'cards': Icons.style_outlined,
    'puzzle': Icons.extension_outlined,
    'palette': Icons.palette_outlined,
    'camera': Icons.camera_alt_outlined,
    'books': Icons.local_library_outlined,
    'book': Icons.menu_book_outlined,
    'bookmark': Icons.bookmark_outlined,
    'newspaper': Icons.article_outlined,
    'sports': Icons.sports_outlined,
    'karaoke': Icons.music_note_outlined,

    // ── Salute & Benessere ──
    'heart': Icons.favorite_outlined,
    'heartbeat': Icons.favorite_border_outlined,
    'first-aid': Icons.medical_services_outlined,
    'pill': Icons.medication_outlined,
    'hospital': Icons.local_hospital_outlined,
    'stethoscope': Icons.biotech_outlined,
    'eye': Icons.visibility_outlined,
    'tooth': Icons.smoking_rooms_outlined, // fumo
    'fitness': Icons.fitness_center_outlined,
    'watch': Icons.watch_outlined,
    'health': Icons.health_and_safety_outlined,
    'bandage': Icons.medical_services_outlined,
    'psychology': Icons.psychology_outlined,
    'blood': Icons.bloodtype_outlined,

    // ── Animali ──
    'dog': Icons.pets_outlined,
    'cat': Icons.cruelty_free_outlined,
    'paw': Icons.pets_outlined,
    'fish': Icons.set_meal_outlined,
    'bug': Icons.bug_report_outlined,
    'leaf': Icons.eco_outlined,
    'tree': Icons.park_outlined,
    'flower': Icons.local_florist_outlined,
    'plant': Icons.yard_outlined,

    // ── Varie ──
    'star': Icons.star_outlined,
    'smiley': Icons.emoji_emotions_outlined,
    'rocket': Icons.rocket_outlined,
    'lightning': Icons.bolt_outlined,
    'fire': Icons.local_fire_department_outlined,
    'water': Icons.water_drop_outlined,
    'snowflake': Icons.ac_unit_outlined,
    'sun': Icons.wb_sunny_outlined,
    'moon': Icons.dark_mode_outlined,
    'cloud': Icons.cloud_outlined,
    'umbrella': Icons.beach_access_outlined,
    'rainbow': Icons.invert_colors_outlined,
    'compass': Icons.explore_outlined,
    'map-pin': Icons.location_on_outlined,
    'map': Icons.map_outlined,
    'flag': Icons.flag_outlined,
    'bell': Icons.notifications_outlined,
    'bell-ringing': Icons.notifications_active_outlined,
    'megaphone': Icons.campaign_outlined,
    'speaker': Icons.volume_up_outlined,
    'crown': Icons.workspace_premium_outlined,
    'medal': Icons.emoji_events_outlined,
    'trophy': Icons.emoji_events,
    'thumbs-up': Icons.thumb_up_outlined,
    'scissors': Icons.content_cut_outlined,
    'clock': Icons.schedule_outlined,
    'calendar': Icons.calendar_month_outlined,
    'calendar-blank': Icons.calendar_today_outlined,
    'calendar-check': Icons.event_available_outlined,
    'calendar-x': Icons.event_busy_outlined,
    'qr-code': Icons.qr_code_outlined,
    'fingerprint': Icons.fingerprint_outlined,
    'circle': Icons.circle_outlined,
    'square': Icons.square_outlined,
    'triangle': Icons.change_history_outlined,
    'hexagon': Icons.hexagon_outlined,
    'question': Icons.question_mark_outlined,
    'info': Icons.info_outlined,
    'warning': Icons.warning_amber_outlined,
    'prohibit': Icons.block_outlined,
    'check-circle': Icons.check_circle_outlined,
    'x-circle': Icons.cancel_outlined,
    'plus-circle': Icons.add_circle_outlined,
    'minus-circle': Icons.remove_circle_outlined,
    'refresh': Icons.refresh_outlined,
    'search': Icons.search_outlined,
    'settings': Icons.settings_outlined,
    'favorite': Icons.favorite_outlined,
    'share': Icons.share_outlined,
    'download': Icons.download_outlined,
    'upload': Icons.upload_outlined,
    'link': Icons.link_outlined,
    'pin': Icons.push_pin_outlined,
    'alarm': Icons.alarm_outlined,
  };

  // ──────────────────────────────────────────────────────────────
  // Account icons
  // ──────────────────────────────────────────────────────────────

  static final Map<String, IconData> _accountIconMap = {
    'wallet': Icons.account_balance_wallet_outlined,
    'bank': Icons.account_balance_outlined,
    'credit-card': Icons.credit_card_outlined,
    'money': Icons.money_outlined,
    'coins': Icons.payments_outlined,
    'hand-coins': Icons.paid_outlined,
    'piggy-bank': Icons.savings_outlined,
    'vault': Icons.lock_outlined,
    'lock': Icons.lock_outline,
    'building': Icons.business_outlined,
    'briefcase': Icons.business_center_outlined,
    'suitcase': Icons.work_outlined,
    'receipt': Icons.receipt_outlined,
    'calculator': Icons.calculate_outlined,
    'chart-bar': Icons.bar_chart_outlined,
    'chart-pie': Icons.pie_chart,
    'trend-up': Icons.trending_up_outlined,
    'card': Icons.credit_card_outlined,
    'safe': Icons.security_outlined,
    'cash': Icons.money_rounded,
  };

  // ──────────────────────────────────────────────────────────────
  // Labels
  // ──────────────────────────────────────────────────────────────

  static const Map<String, String> _categoryIconLabels = {
    // Veicoli
    'car': 'Auto',
    'motorcycle': 'Moto',
    'bicycle': 'Bici',
    'scooter': 'Monopattino',
    'bus': 'Bus',
    'train': 'Treno',
    'airplane': 'Aereo',
    'boat': 'Nave',
    'taxi': 'Taxi',
    'truck': 'Camion',
    'walk': 'Piedi',
    'hiking': 'Escursione',
    'car-simple': 'Auto semplice',
    'gas-pump': 'Benzina',
    'park': 'Parcheggio',
    'bird': 'Motocicletta',

    // Casa
    'house': 'Casa',
    'building': 'Edificio',
    'house-line': 'Casa filare',
    'garage': 'Garage',
    'door': 'Porta',
    'window': 'Finestra',
    'sofa': 'Divano',
    'chair': 'Sedia',
    'bed': 'Letto',
    'lamp': 'Lampada',
    'lightbulb': 'Lampadina',
    'fan': 'Ventilatore',
    'key': 'Chiave',
    'lock': 'Lucchetto',
    'shower': 'Doccia',
    'bathtub': 'Vasca',
    'toolbox': 'Attrezzi',
    'wrench': 'Chiave inglese',
    'ladder': 'Scala',

    // Cibo & Cucina
    'shopping-cart': 'Spesa',
    'restaurant': 'Ristorante',
    'coffee': 'Caffè',
    'cake': 'Dolce',
    'pizza': 'Pizza',
    'hamburger': 'Fast food',
    'beer': 'Birra',
    'food': 'Cibo',
    'ice-cream': 'Gelato',
    'cookie': 'Biscotto',
    'wine': 'Vino',
    'bread': 'Pane',
    'apple': 'Mela',
    'kebab': 'Kebab',
    'tea': 'Tè',
    'fastfood': 'Fast food',
    'egg': 'Uovo',
    'brunch': 'Brunch',
    'liquor': 'Liquore',
    'takeout': 'Takeout',

    // Shopping
    'shopping-bag': 'Borsa spesa',
    'shopping-cart-2': 'Carrello 2',
    'tag': 'Etichetta',
    'hanger': 'Gruccia',
    'gift': 'Regalo',
    'bag': 'Borsa',
    'storefront': 'Negozio',
    'barcode': 'Codice a barre',
    'tote': 'Tote bag',
    'handbag': 'Borsetta',
    'shoe': 'Scarpa',
    'diamond': 'Diamante',

    // Finanza & Entrate
    'money': 'Denaro',
    'bank': 'Banca',
    'wallet': 'Portafoglio',
    'cash': 'Contanti',
    'coins': 'Monete',
    'hand-coins': 'Mano monete',
    'piggy-bank': 'Salvadanaio',
    'receipt': 'Scontrino',
    'receipt-x': 'Scontrino annullato',
    'file-text': 'Fattura',
    'calculator': 'Calcolatrice',
    'percentage': 'Percentuale',
    'currency-dollar': 'Dollaro',
    'currency-eur': 'Euro',
    'currency-gbp': 'Sterlina',
    'trend-up': 'Trend in salita',
    'trend-down': 'Trend in discesa',
    'chart-bar': 'Grafico barre',
    'chart-pie': 'Grafico a torta',
    'chart-line': 'Grafico lineare',

    // Lavoro & Istruzione
    'briefcase': 'Valigetta',
    'suitcase': 'Valigia',
    'laptop': 'Computer',
    'desktop': 'Desktop',
    'backpack': 'Zaino',
    'clipboard': 'Appunti',
    'paperclip': 'Clip',
    'envelope': 'Lettera',
    'chat': 'Chat',
    'users': 'Utenti',
    'user': 'Utente',
    'user-circle': 'Utente cerchio',
    'badge': 'Badge',
    'certificate': 'Certificato',
    'book-open': 'Libro aperto',
    'graduation-cap': 'Laurea',
    'pencil': 'Matita',
    'pen': 'Penna',
    'globe': 'Globo',
    'atom': 'Atomo',
    'flask': 'Becher',
    'card': 'Tessera',

    // Tecnologia
    'smartphone': 'Smartphone',
    'tablet': 'Tablet',
    'computer': 'Computer',
    'monitor': 'Monitor',
    'printer': 'Stampante',
    'wifi': 'Wi-Fi',
    'hard-drive': 'Hard disk',
    'sim-card': 'SIM',
    'plug': 'Cavo',
    'battery': 'Batteria',
    'cable': 'USB',
    'database': 'Database',
    'memory': 'Memoria',
    'security': 'Sicurezza',

    // Tempo Libero
    'game-controller': 'Console',
    'film': 'Film',
    'movie': 'Cinema',
    'music-note': 'Nota musicale',
    'music-notes': 'Note musicali',
    'headphones': 'Cuffie',
    'microphone': 'Microfono',
    'ticket': 'Biglietto',
    'popcorn': 'Popcorn',
    'confetti': 'Coriandoli',
    'dice': 'Dadi',
    'cards': 'Carte',
    'puzzle': 'Puzzle',
    'palette': 'Tavolozza',
    'camera': 'Fotocamera',
    'books': 'Libri',
    'book': 'Libro',
    'bookmark': 'Segnalibro',
    'newspaper': 'Giornale',
    'sports': 'Sport',
    'karaoke': 'Karaoke',

    // Salute & Benessere
    'heart': 'Cuore',
    'heartbeat': 'Battito',
    'first-aid': 'Pronto soccorso',
    'pill': 'Pillola',
    'hospital': 'Ospedale',
    'stethoscope': 'Stetoscopio',
    'eye': 'Occhio',
    'tooth': 'Fumo',
    'fitness': 'Palestra',
    'watch': 'Orologio',
    'health': 'Salute',
    'bandage': 'Cerotto',
    'psychology': 'Psicologia',
    'blood': 'Sangue',

    // Animali
    'dog': 'Cane',
    'cat': 'Gatto',
    'paw': 'Zampa',
    'fish': 'Pesce',
    'bug': 'Insetto',
    'leaf': 'Foglia',
    'tree': 'Albero',
    'flower': 'Fiore',
    'plant': 'Pianta',

    // Varie
    'star': 'Stella',
    'smiley': 'Sorriso',
    'rocket': 'Razzo',
    'lightning': 'Fulmine',
    'fire': 'Fuoco',
    'water': 'Acqua',
    'snowflake': 'Fiocco di neve',
    'sun': 'Sole',
    'moon': 'Luna',
    'cloud': 'Nuvola',
    'umbrella': 'Ombrello',
    'rainbow': 'Arcobaleno',
    'compass': 'Bussola',
    'map-pin': 'Pin mappa',
    'map': 'Mappa',
    'flag': 'Bandiera',
    'bell': 'Campanella',
    'bell-ringing': 'Campanella suono',
    'megaphone': 'Megafono',
    'speaker': 'Altoparlante',
    'crown': 'Corona',
    'medal': 'Medaglia',
    'trophy': 'Trofeo',
    'thumbs-up': 'Pollice su',
    'scissors': 'Forbici',
    'clock': 'Orologio',
    'calendar': 'Calendario',
    'calendar-blank': 'Calendario vuoto',
    'calendar-check': 'Calendario check',
    'calendar-x': 'Calendario X',
    'qr-code': 'QR code',
    'fingerprint': 'Impronta',
    'circle': 'Cerchio',
    'square': 'Quadrato',
    'triangle': 'Triangolo',
    'hexagon': 'Esagono',
    'question': 'Domanda',
    'info': 'Info',
    'warning': 'Attenzione',
    'prohibit': 'Vietato',
    'check-circle': 'Check',
    'x-circle': 'X',
    'plus-circle': 'Più',
    'minus-circle': 'Meno',
    'refresh': 'Aggiorna',
    'search': 'Cerca',
    'settings': 'Impostazioni',
    'favorite': 'Preferito',
    'share': 'Condividi',
    'download': 'Scarica',
    'upload': 'Carica',
    'link': 'Link',
    'pin': 'Spillo',
    'alarm': 'Sveglia',
  };

  static const Map<String, String> _accountIconLabels = {
    'wallet': 'Portafoglio',
    'bank': 'Banca',
    'credit-card': 'Carta di credito',
    'money': 'Denaro',
    'coins': 'Monete',
    'hand-coins': 'Mano monete',
    'piggy-bank': 'Salvadanaio',
    'vault': 'Caveau',
    'lock': 'Lucchetto',
    'building': 'Edificio',
    'briefcase': 'Valigetta',
    'suitcase': 'Valigia',
    'receipt': 'Scontrino',
    'calculator': 'Calcolatrice',
    'chart-bar': 'Grafico',
    'chart-pie': 'Torta',
    'trend-up': 'Trend',
    'card': 'Tessera',
    'safe': 'Sicurezza',
    'cash': 'Contanti',
  };

  // ──────────────────────────────────────────────────────────────
  // Groups — category icons
  // ──────────────────────────────────────────────────────────────

  static const Map<String, List<String>> categoryIconGroups = {
    'Veicoli': [
      'car', 'motorcycle', 'bird', 'bicycle', 'scooter',
      'bus', 'train', 'airplane', 'boat',
      'taxi', 'truck', 'walk', 'hiking',
      'car-simple', 'gas-pump', 'park',
    ],
    'Casa': [
      'house', 'building', 'house-line', 'garage', 'door', 'window',
      'sofa', 'chair', 'bed', 'lamp', 'lightbulb', 'fan',
      'key', 'lock', 'shower', 'bathtub', 'toolbox', 'wrench', 'ladder',
    ],
    'Cibo & Cucina': [
      'shopping-cart', 'restaurant', 'coffee', 'cake', 'pizza',
      'hamburger', 'beer', 'food', 'ice-cream', 'cookie', 'wine',
      'bread', 'apple', 'kebab', 'tea', 'fastfood', 'egg',
      'brunch', 'liquor', 'takeout',
    ],
    'Shopping': [
      'shopping-bag', 'shopping-cart-2', 'tag', 'hanger', 'gift',
      'bag', 'storefront', 'barcode', 'tote', 'handbag', 'shoe', 'diamond',
    ],
    'Finanza & Entrate': [
      'money', 'bank', 'wallet', 'cash', 'coins', 'hand-coins',
      'piggy-bank', 'receipt', 'receipt-x', 'file-text', 'calculator',
      'percentage', 'currency-dollar', 'currency-eur', 'currency-gbp',
      'trend-up', 'trend-down', 'chart-bar', 'chart-pie', 'chart-line',
    ],
    'Lavoro & Istruzione': [
      'briefcase', 'suitcase', 'laptop', 'desktop', 'backpack',
      'clipboard', 'paperclip', 'envelope', 'chat', 'users', 'user',
      'user-circle', 'badge', 'certificate', 'book-open', 'graduation-cap',
      'pencil', 'pen', 'globe', 'atom', 'flask', 'card',
    ],
    'Tecnologia': [
      'smartphone', 'tablet', 'computer', 'monitor', 'printer',
      'wifi', 'hard-drive', 'sim-card', 'plug', 'battery', 'cable',
      'database', 'memory', 'security',
    ],
    'Tempo Libero': [
      'game-controller', 'film', 'movie', 'music-note', 'music-notes',
      'headphones', 'microphone', 'ticket', 'popcorn', 'confetti',
      'dice', 'cards', 'puzzle', 'palette', 'camera', 'books', 'book',
      'bookmark', 'newspaper', 'sports', 'karaoke',
    ],
    'Salute & Benessere': [
      'heart', 'heartbeat', 'first-aid', 'pill', 'hospital',
      'stethoscope', 'eye', 'tooth', 'fitness', 'watch', 'health',
      'bandage', 'psychology', 'blood',
    ],
    'Animali & Natura': [
      'dog', 'cat', 'paw', 'fish', 'bug',
      'leaf', 'tree', 'flower', 'plant',
    ],
    'Varie': [
      'star', 'smiley', 'rocket', 'lightning', 'fire', 'water',
      'snowflake', 'sun', 'moon', 'cloud', 'umbrella', 'rainbow',
      'compass', 'map-pin', 'map', 'flag', 'bell', 'bell-ringing',
      'megaphone', 'speaker', 'crown', 'medal', 'trophy', 'thumbs-up',
      'scissors', 'clock',
      'calendar', 'calendar-blank', 'calendar-check', 'calendar-x',
      'qr-code', 'fingerprint',
      'circle', 'square', 'triangle', 'hexagon',
      'question', 'info', 'warning', 'prohibit',
      'check-circle', 'x-circle', 'plus-circle', 'minus-circle',
      'refresh', 'search', 'settings', 'favorite',
      'share', 'download', 'upload', 'link', 'pin', 'alarm',
    ],
  };

  // ──────────────────────────────────────────────────────────────
  // Groups — account icons
  // ──────────────────────────────────────────────────────────────

  static const Map<String, List<String>> accountIconGroups = {
    'Principali': ['wallet', 'bank', 'credit-card', 'money', 'cash'],
    'Risparmio': ['coins', 'hand-coins', 'piggy-bank', 'vault', 'safe'],
    'Strumenti': ['calculator', 'receipt', 'card'],
    'Analisi': ['chart-bar', 'chart-pie', 'trend-up'],
    'Lavoro': ['briefcase', 'suitcase', 'building'],
    'Altro': ['lock'],
  };

  // ──────────────────────────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────────────────────────

  static List<StreamIconGroup> get categoryIconGroupsList {
    return categoryIconGroups.entries.map((entry) {
      final entries = entry.value
          .where((k) => _iconMap.containsKey(k))
          .map((k) => StreamIconEntry(
                k,
                _categoryIconLabels[k] ?? k,
                _iconMap[k]!,
              ))
          .toList();
      return StreamIconGroup(entry.key, entries);
    }).toList();
  }

  static List<StreamIconGroup> get accountIconGroupsList {
    return accountIconGroups.entries.map((entry) {
      final entries = entry.value
          .where((k) => _accountIconMap.containsKey(k))
          .map((k) => StreamIconEntry(
                k,
                _accountIconLabels[k] ?? k,
                _accountIconMap[k]!,
              ))
          .toList();
      return StreamIconGroup(entry.key, entries);
    }).toList();
  }

  static List<MapEntry<String, String>> get categoryIconsWithLabels {
    return _categoryIconLabels.entries.toList();
  }

  static List<MapEntry<String, String>> get accountIconsWithLabels {
    return _accountIconLabels.entries.toList();
  }

  static Set<String> get allGroupNames =>
      categoryIconGroups.keys.toSet();

  static String? findGroupForKey(String iconKey) {
    for (final entry in categoryIconGroups.entries) {
      if (entry.value.contains(iconKey)) return entry.key;
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────
  // Resolution
  // ──────────────────────────────────────────────────────────────

  static IconData getIcon(String iconKey) {
    return _iconMap[iconKey] ?? fallbackIcon;
  }

  static IconData getAccountIcon(String iconKey) {
    return _accountIconMap[iconKey] ?? fallbackIcon;
  }

  static String getLabel(String iconKey) {
    return _categoryIconLabels[iconKey] ?? iconKey;
  }

  static String getAccountLabel(String iconKey) {
    return _accountIconLabels[iconKey] ?? iconKey;
  }
}

class StreamColorPalette {
  static const List<int> colors = [
    0xFFEF5350,
    0xFFE53935,
    0xFFEC407A,
    0xFFE91E63,
    0xFFAB47BC,
    0xFF9C27B0,
    0xFF7E57C2,
    0xFF673AB7,
    0xFF5C6BC0,
    0xFF3F51B5,
    0xFF42A5F5,
    0xFF2196F3,
    0xFF29B6F6,
    0xFF03A9F4,
    0xFF26C6DA,
    0xFF00BCD4,
    0xFF26A69A,
    0xFF009688,
    0xFF66BB6A,
    0xFF4CAF50,
    0xFF9CCC65,
    0xFF8BC34A,
    0xFFD4E157,
    0xFFCDDC39,
    0xFFFFEE58,
    0xFFFDD835,
    0xFFFFCA28,
    0xFFFFB300,
    0xFFFFA726,
    0xFFFF9800,
    0xFFFF7043,
    0xFFE64A19,
  ];

  static const int defaultColor = 0xFFEF5350;

  static int getDefault() => defaultColor;
}
