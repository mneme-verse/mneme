// cspell:disable

import 'package:mneme/db/database.dart';

Future<void> seedDatabase(AppDatabase db, {String? language}) async {
  final allPoems = {
    'en': [
      {
        'title': 'The Raven',
        'author_names': 'Edgar Allan Poe',
        'body': 'Once upon a midnight dreary...',
        'year': '1845',
      },
      {
        'title': 'Annabel Lee',
        'author_names': 'Edgar Allan Poe',
        'body': 'It was many and many a year ago...',
        'year': '1849',
      },
      {
        'title': 'Ozymandias',
        'author_names': 'Percy Bysshe Shelley',
        'body': 'I met a traveller from an antique land...',
        'year': '1818',
      },
      {
        'title': 'Daffodils',
        'author_names': 'William Wordsworth',
        'body': 'I wandered lonely as a cloud...',
        'year': '1807',
      },
    ],
    'ru': [
      {
        'title': 'Я помню чудное мгновенье',
        'author_names': 'Александр Пушкин',
        'body': 'Я помню чудное мгновенье:\nПередо мной явилась ты...',
        'year': '1825',
      },
      {
        'title': 'Silentium!',
        'author_names': 'Фёдор Тютчев',
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

  // Extract and insert authors for testing
  // Note: ID assignment is simplified here for tests
  final authorsMap = <String, int>{}; // name -> author ID
  final authorsList = <Map<String, dynamic>>[];
  final poemAuthorsList = <Map<String, dynamic>>[];
  var authorIdCounter = 1;
  var poemIdCounter = 1;

  for (final poem in poems) {
    final authorName = poem['author_names']!;
    int authorId;

    if (!authorsMap.containsKey(authorName)) {
      authorId = authorIdCounter++;
      authorsMap[authorName] = authorId;
      authorsList.add({
        'id': authorId,
        'name': authorName,
        'poem_count': 1,
      });
    } else {
      authorId = authorsMap[authorName]!;
      // Find and update poem count
      final authorEntry = authorsList.firstWhere((a) => a['id'] == authorId);
      authorEntry['poem_count'] = (authorEntry['poem_count'] as int) + 1;
    }

    // Create PoemAuthor relationship
    poemAuthorsList.add({
      'poem_id': poemIdCounter,
      'author_id': authorId,
    });

    poemIdCounter++;
  }

  await db.batchInsertAuthors(authorsList);
  await db.batchInsertPoemAuthors(poemAuthorsList);
}
