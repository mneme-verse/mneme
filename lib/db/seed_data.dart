import 'dart:convert';

import 'package:mneme/db/database.dart';

Future<void> seedDatabase(AppDatabase db, {String? language}) async {
  final allPoems = {
    'en': [
      {
        'title': 'The Raven',
        'author': json.encode(['Edgar Allan Poe']),
        'body': 'Once upon a midnight dreary...',
        'year': '1845',
      },
      {
        'title': 'Ozymandias',
        'author': json.encode(['Percy Bysshe Shelley']),
        'body': 'I met a traveller from an antique land...',
        'year': '1818',
      },
      {
        'title': 'Daffodils',
        'author': json.encode(['William Wordsworth']),
        'body': 'I wandered lonely as a cloud...',
        'year': '1807',
      },
    ],
    'ru': [
      {
        'title': 'Я помню чудное мгновенье',
        'author': json.encode(['Александр Пушкин']),
        'body': 'Я помню чудное мгновенье:\nПередо мной явилась ты...',
        'year': '1825',
      },
      {
        'title': 'Silentium!',
        'author': json.encode(['Фёдор Тютчев']),
        'body': 'Молчи, скрывайся и таи\nИ чувства и мечты свои...',
        'year': '1830',
      },
    ],
  };

  // If language is specified, use only that language's poems
  // Otherwise, use all poems for compatibility
  final poems = language != null
      ? (allPoems[language] ?? [])
      : [...allPoems['en']!, ...allPoems['ru']!];

  await db.batchInsertPoems(poems);
}
