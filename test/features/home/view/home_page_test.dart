import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/features/home/bloc/home_cubit.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/l10n/gen/app_localizations.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockPoetryRepository extends Mock implements PoetryRepository {}

void main() {
  group('HomePage', () {
    late HomeCubit homeCubit;
    late PoetryRepository poetryRepository;

    setUp(() {
      homeCubit = MockHomeCubit();
      poetryRepository = MockPoetryRepository();
      when(() => homeCubit.state).thenReturn(HomeLoading());
      // Mock fetchAuthors to avoid null errors if called in initState/builder
      when(
        () => homeCubit.fetchAuthors(offset: any(named: 'offset')),
      ).thenAnswer((_) async {});
    });

    Widget buildSubject() {
      return RepositoryProvider.value(
        value: poetryRepository,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: homeCubit,
            child: const HomeView(),
          ),
        ),
      );
    }

    testWidgets('renders CircularProgressIndicator when state is HomeLoading', (
      tester,
    ) async {
      when(() => homeCubit.state).thenReturn(HomeLoading());
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error text when state is HomeError', (tester) async {
      when(() => homeCubit.state).thenReturn(HomeError('oops'));
      await tester.pumpWidget(buildSubject());
      expect(find.text('Error: oops'), findsOneWidget);
    });

    testWidgets('renders list of authors when state is HomeLoaded', (
      tester,
    ) async {
      final authors = [
        const Author(name: 'Author 1', poemCount: 5, id: 1),
        const Author(name: 'Author 2', poemCount: 3, id: 2),
      ];
      when(() => homeCubit.state).thenReturn(HomeLoaded(authors));
      await tester.pumpWidget(buildSubject());

      expect(find.text('Author 1'), findsOneWidget);
      expect(find.text('5 poems'), findsOneWidget);
      expect(find.text('Author 2'), findsOneWidget);
    });

    testWidgets('renders "No authors found" when list is empty', (
      tester,
    ) async {
      when(
        () => homeCubit.state,
      ).thenReturn(HomeLoaded([], hasReachedMax: true));
      await tester.pumpWidget(buildSubject());
      expect(find.text('No authors found'), findsOneWidget);
    });

    testWidgets('taps search button', (tester) async {
      final authors = [const Author(name: 'Author 1', poemCount: 5, id: 1)];
      when(() => homeCubit.state).thenReturn(HomeLoaded(authors));
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
      await tester.pump();
    });

    testWidgets('taps settings button', (tester) async {
      final authors = [const Author(name: 'Author 1', poemCount: 5, id: 1)];
      when(
        () => homeCubit.state,
      ).thenReturn(HomeLoaded(authors, hasReachedMax: true));

      var settingsPressed = false;
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: poetryRepository,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider.value(
              value: homeCubit,
              child: HomeView(
                onSettingsPressed: () => settingsPressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.settings));
      await tester.pumpAndSettle();

      expect(settingsPressed, isTrue);
    });

    testWidgets('taps author item', (tester) async {
      final authors = [const Author(name: 'Author 1', poemCount: 5, id: 1)];
      when(() => homeCubit.state).thenReturn(HomeLoaded(authors));
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Author 1'));
      await tester.pump();
    });

    testWidgets('shows loading indicator when more items available', (
      tester,
    ) async {
      final authors = [const Author(name: 'Author 1', poemCount: 5, id: 1)];
      when(() => homeCubit.state).thenReturn(HomeLoaded(authors));
      await tester.pumpWidget(buildSubject());

      // Should show an extra loading indicator at the end
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'calls fetchAuthors on scroll to end when not at max',
      (tester) async {
        final scrollController = ScrollController();
        final authors = List.generate(
          50,
          (i) => Author(name: 'Author $i', poemCount: 5, id: i),
        );
        when(() => homeCubit.state).thenReturn(HomeLoaded(authors));
        when(() => homeCubit.fetchAuthors(offset: 50)).thenAnswer((_) async {});

        await tester.pumpWidget(
          RepositoryProvider.value(
            value: poetryRepository,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SizedBox(
                height: 300,
                child: BlocProvider.value(
                  value: homeCubit,
                  child: HomeView(scrollController: scrollController),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Jump to end of list to trigger pagination
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();

        verify(() => homeCubit.fetchAuthors(offset: 50)).called(greaterThan(0));
      },
    );

    testWidgets(
      'does not call fetchAuthors when hasReachedMax is true',
      (tester) async {
        final scrollController = ScrollController();
        final authors = List.generate(
          5,
          (i) => Author(name: 'Author $i', poemCount: 5, id: i),
        );
        when(
          () => homeCubit.state,
        ).thenReturn(HomeLoaded(authors, hasReachedMax: true));

        await tester.pumpWidget(
          RepositoryProvider.value(
            value: poetryRepository,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: BlocProvider.value(
                value: homeCubit,
                child: HomeView(scrollController: scrollController),
              ),
            ),
          ),
        );

        // Jump to end
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pumpAndSettle();

        // Verify fetchAuthors was NOT called with offset
        verifyNever(() => homeCubit.fetchAuthors(offset: 5));
      },
    );
  });

  group('HomePage initialization', () {
    late PoetryRepository poetryRepository;

    setUp(() {
      poetryRepository = MockPoetryRepository();
    });

    testWidgets('route returns a MaterialPageRoute', (tester) async {
      expect(HomePage.route(), isA<MaterialPageRoute<void>>());
    });

    testWidgets('renders HomeView', (tester) async {
      when(
        () => poetryRepository.getAuthors(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        RepositoryProvider.value(
          value: poetryRepository,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomePage(),
          ),
        ),
      );

      expect(find.byType(HomeView), findsOneWidget);
    });
  });
}
