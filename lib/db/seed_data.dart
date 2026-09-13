// cspell:disable

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mneme/db/database.dart';

Future<void> seedDatabase(AppDatabase db, {String? language}) async {
  final allPoems = {
    'en': [
      {
        'id': 1,
        'title': 'The Raven',
        'author_names': 'Edgar Allan Poe',
        'body': 'Once upon a midnight dreary...',
        'year': '1845',
        'poemKey': 'poetree:en:raven',
        'language': 'en',
      },
      {
        'id': 2,
        'title': 'Annabel Lee',
        'author_names': 'Edgar Allan Poe',
        'body': 'It was many and many a year ago...',
        'year': '1849',
        'poemKey': 'poetree:en:annabel-lee',
        'language': 'en',
      },
      {
        'id': 3,
        'title': 'Ozymandias',
        'author_names': 'Percy Bysshe Shelley',
        'body': 'I met a traveller from an antique land...',
        'year': '1818',
        'poemKey': 'poetree:en:ozymandias',
        'language': 'en',
      },
      {
        'id': 4,
        'title': 'Daffodils',
        'author_names': 'William Wordsworth',
        'body': 'I wandered lonely as a cloud...',
        'year': '1807',
        'poemKey': 'poetree:en:daffodils',
        'language': 'en',
      },
    ],
    'ru': [
      {
        'id': 5,
        'title': 'Я помню чудное мгновенье',
        'author_names': 'Александр Пушкин',
        'body': 'Я помню чудное мгновенье:\nПередо мной явилась ты...',
        'year': '1825',
        'poemKey': 'poetree:ru:k-cheriomukham',
        'language': 'ru',
      },
      {
        'id': 6,
        'title': 'Silentium!',
        'author_names': 'Фёдор Тютчев',
        'body': 'Молчи, скрывайся и таи\nИ чувства и мечты свои...',
        'year': '1830',
        'poemKey': 'poetree:ru:silentium',
        'language': 'ru',
      },
    ],
  };

  // If language is specified, use only that language's poems
  // Otherwise, use all poems for compatibility
  final poems = language != null
      ? (allPoems[language] ?? [])
      : [...allPoems['en']!, ...allPoems['ru']!];

  for (final poem in poems) {
    final body = poem['body']! as String;
    poem['contentHash'] = sha256.convert(utf8.encode(body)).toString();
  }

  await db.batchInsertPoems(poems);

  // Extract and insert authors for testing
  // Note: ID assignment is simplified here for tests
  final authorsMap = <String, int>{}; // name -> author ID
  final authorsList = <Map<String, dynamic>>[];
  final poemAuthorsList = <Map<String, dynamic>>[];
  var authorIdCounter = 1;

  for (final poem in poems) {
    final authorName = poem['author_names']! as String;
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

    // Create PoemAuthor relationship from the poem's real id: seed rows
    // carry explicit ids (Russian rows are 5 and 6), so a separate
    // counter would link them to nonexistent poems.
    poemAuthorsList.add({
      'poem_id': poem['id'],
      'author_id': authorId,
    });
  }

  await db.batchInsertAuthors(authorsList);
  await db.batchInsertPoemAuthors(poemAuthorsList);
}
