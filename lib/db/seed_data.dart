import 'package:drift/drift.dart';
import 'package:mneme/db/database.dart';

Future<void> seedDatabase(AppDatabase db) async {
  await db.batch((batch) {
    batch.insertAll(db.poems, [
      PoemsCompanion.insert(
        title: 'The Raven',
        author: 'Edgar Allan Poe',
        body: 'Once upon a midnight dreary...',
        year: const Value('1845'),
        language: 'en',
      ),
      PoemsCompanion.insert(
        title: 'Ozymandias',
        author: 'Percy Bysshe Shelley',
        body: 'I met a traveller from an antique land...',
        year: const Value('1818'),
        language: 'en',
      ),
      PoemsCompanion.insert(
        title: 'Daffodils',
        author: 'William Wordsworth',
        body: 'I wandered lonely as a cloud...',
        year: const Value('1807'),
        language: 'en',
      ),
      PoemsCompanion.insert(
        title: 'Я помню чудное мгновенье',
        author: 'Александр Пушкин',
        body: 'Я помню чудное мгновенье:\nПередо мной явилась ты...',
        year: const Value('1825'),
        language: 'ru',
      ),
      PoemsCompanion.insert(
        title: 'Silentium!',
        author: 'Фёдор Тютчев',
        body: 'Молчи, скрывайся и таи\nИ чувства и мечты свои...',
        year: const Value('1830'),
        language: 'ru',
      ),
    ]);
  });
}
