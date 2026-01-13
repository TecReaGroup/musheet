/// Annotation Model Tests
///
/// Unit tests for Annotation model including serialization and various annotation types.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/annotation.dart';

import '../../fixtures/test_fixtures.dart';

void main() {
  group('Annotation Model', () {
    group('Construction', () {
      test('creates draw annotation with required fields', () {
        final annotation = Annotation(
          id: 'ann_1',
          type: 'draw',
          color: '#000000',
          width: 2.0,
          points: [0.1, 0.2, 0.3, 0.4],
          page: 1,
        );

        expect(annotation.id, equals('ann_1'));
        expect(annotation.type, equals('draw'));
        expect(annotation.color, equals('#000000'));
        expect(annotation.width, equals(2.0));
        expect(annotation.points, equals([0.1, 0.2, 0.3, 0.4]));
        expect(annotation.page, equals(1));
      });

      test('creates text annotation with required fields', () {
        final annotation = Annotation(
          id: 'ann_1',
          type: 'text',
          color: '#FF0000',
          width: 1.0,
          text: 'Annotation text',
          x: 0.5,
          y: 0.3,
          page: 2,
        );

        expect(annotation.type, equals('text'));
        expect(annotation.text, equals('Annotation text'));
        expect(annotation.x, equals(0.5));
        expect(annotation.y, equals(0.3));
        expect(annotation.page, equals(2));
      });

      test('has default page value of 1', () {
        final annotation = Annotation(
          id: 'ann_1',
          type: 'draw',
          color: '#000000',
          width: 2.0,
        );

        expect(annotation.page, equals(1));
      });

      test('optional fields are null when not provided', () {
        final annotation = Annotation(
          id: 'ann_1',
          type: 'draw',
          color: '#000000',
          width: 2.0,
        );

        expect(annotation.points, isNull);
        expect(annotation.text, isNull);
        expect(annotation.x, isNull);
        expect(annotation.y, isNull);
      });
    });

    group('Draw Annotations', () {
      test('supports multiple points for freehand drawing', () {
        final points = <double>[];
        for (int i = 0; i < 100; i++) {
          points.add(i / 100.0);
          points.add(i / 100.0);
        }

        final annotation = Annotation(
          id: 'ann_freehand',
          type: 'draw',
          color: '#0000FF',
          width: 3.0,
          points: points,
          page: 1,
        );

        expect(annotation.points!.length, equals(200));
      });

      test('supports various colors', () {
        final colors = ['#000000', '#FFFFFF', '#FF0000', '#00FF00', '#0000FF', '#FFFF00'];

        for (final color in colors) {
          final annotation = Annotation(
            id: 'ann_$color',
            type: 'draw',
            color: color,
            width: 2.0,
            page: 1,
          );

          expect(annotation.color, equals(color));
        }
      });

      test('supports various widths', () {
        final widths = [0.5, 1.0, 2.0, 5.0, 10.0];

        for (final width in widths) {
          final annotation = Annotation(
            id: 'ann_w$width',
            type: 'draw',
            color: '#000000',
            width: width,
            page: 1,
          );

          expect(annotation.width, equals(width));
        }
      });
    });

    group('Text Annotations', () {
      test('stores text content', () {
        final annotation = Annotation(
          id: 'ann_text',
          type: 'text',
          color: '#000000',
          width: 14.0, // Font size
          text: 'Piano forte',
          x: 0.25,
          y: 0.75,
          page: 3,
        );

        expect(annotation.text, equals('Piano forte'));
        expect(annotation.x, equals(0.25));
        expect(annotation.y, equals(0.75));
      });

      test('handles empty text', () {
        final annotation = Annotation(
          id: 'ann_empty',
          type: 'text',
          color: '#000000',
          width: 12.0,
          text: '',
          x: 0.5,
          y: 0.5,
          page: 1,
        );

        expect(annotation.text, equals(''));
      });

      test('handles special characters in text', () {
        final annotation = Annotation(
          id: 'ann_special',
          type: 'text',
          color: '#000000',
          width: 12.0,
          text: 'Test \n with "quotes" & special <chars>',
          x: 0.5,
          y: 0.5,
          page: 1,
        );

        expect(annotation.text, contains('\n'));
        expect(annotation.text, contains('"'));
        expect(annotation.text, contains('&'));
      });
    });

    group('Page Management', () {
      test('annotations can be on different pages', () {
        final pages = [1, 2, 3, 10, 100];

        for (final page in pages) {
          final annotation = Annotation(
            id: 'ann_p$page',
            type: 'draw',
            color: '#000000',
            width: 2.0,
            page: page,
          );

          expect(annotation.page, equals(page));
        }
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct map for draw annotation', () {
        final annotation = Annotation(
          id: 'ann_1',
          type: 'draw',
          color: '#FF0000',
          width: 3.0,
          points: [0.1, 0.2, 0.3, 0.4],
          page: 2,
        );

        final json = annotation.toJson();

        expect(json['id'], equals('ann_1'));
        expect(json['type'], equals('draw'));
        expect(json['color'], equals('#FF0000'));
        expect(json['width'], equals(3.0));
        expect(json['points'], equals([0.1, 0.2, 0.3, 0.4]));
        expect(json['page'], equals(2));
        expect(json['text'], isNull);
        expect(json['x'], isNull);
        expect(json['y'], isNull);
      });

      test('toJson produces correct map for text annotation', () {
        final annotation = Annotation(
          id: 'ann_1',
          type: 'text',
          color: '#0000FF',
          width: 14.0,
          text: 'Test text',
          x: 0.5,
          y: 0.75,
          page: 3,
        );

        final json = annotation.toJson();

        expect(json['id'], equals('ann_1'));
        expect(json['type'], equals('text'));
        expect(json['text'], equals('Test text'));
        expect(json['x'], equals(0.5));
        expect(json['y'], equals(0.75));
        expect(json['page'], equals(3));
        expect(json['points'], isNull);
      });

      test('fromJson creates draw annotation from map', () {
        final json = {
          'id': 'ann_1',
          'type': 'draw',
          'color': '#FF0000',
          'width': 3.0,
          'points': [0.1, 0.2, 0.3, 0.4],
          'page': 2,
        };

        final annotation = Annotation.fromJson(json);

        expect(annotation.id, equals('ann_1'));
        expect(annotation.type, equals('draw'));
        expect(annotation.color, equals('#FF0000'));
        expect(annotation.width, equals(3.0));
        expect(annotation.points, equals([0.1, 0.2, 0.3, 0.4]));
        expect(annotation.page, equals(2));
      });

      test('fromJson creates text annotation from map', () {
        final json = {
          'id': 'ann_1',
          'type': 'text',
          'color': '#0000FF',
          'width': 14.0,
          'text': 'Test text',
          'x': 0.5,
          'y': 0.75,
          'page': 3,
        };

        final annotation = Annotation.fromJson(json);

        expect(annotation.id, equals('ann_1'));
        expect(annotation.type, equals('text'));
        expect(annotation.text, equals('Test text'));
        expect(annotation.x, equals(0.5));
        expect(annotation.y, equals(0.75));
        expect(annotation.page, equals(3));
      });

      test('fromJson handles missing page with default 1', () {
        final json = {
          'id': 'ann_1',
          'type': 'draw',
          'color': '#000000',
          'width': 2.0,
        };

        final annotation = Annotation.fromJson(json);

        expect(annotation.page, equals(1));
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'id': 'ann_1',
          'type': 'draw',
          'color': '#000000',
          'width': 2.0,
          'points': null,
          'text': null,
          'x': null,
          'y': null,
        };

        final annotation = Annotation.fromJson(json);

        expect(annotation.points, isNull);
        expect(annotation.text, isNull);
        expect(annotation.x, isNull);
        expect(annotation.y, isNull);
      });

      test('toJson and fromJson are symmetric for draw annotation', () {
        final original = Annotation(
          id: 'ann_1',
          type: 'draw',
          color: '#FF0000',
          width: 3.5,
          points: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
          page: 5,
        );

        final json = original.toJson();
        final restored = Annotation.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.color, equals(original.color));
        expect(restored.width, equals(original.width));
        expect(restored.points, equals(original.points));
        expect(restored.page, equals(original.page));
      });

      test('toJson and fromJson are symmetric for text annotation', () {
        final original = Annotation(
          id: 'ann_1',
          type: 'text',
          color: '#0000FF',
          width: 16.0,
          text: 'Test annotation text',
          x: 0.25,
          y: 0.8,
          page: 3,
        );

        final json = original.toJson();
        final restored = Annotation.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.color, equals(original.color));
        expect(restored.width, equals(original.width));
        expect(restored.text, equals(original.text));
        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.page, equals(original.page));
      });
    });

    group('TestFixtures Integration', () {
      test('createAnnotation creates valid annotation', () {
        final annotation = TestFixtures.createAnnotation(
          id: 'test_ann',
          page: 3,
          color: '#ABCDEF',
          width: 4.0,
        );

        expect(annotation.id, equals('test_ann'));
        expect(annotation.page, equals(3));
        expect(annotation.color, equals('#ABCDEF'));
        expect(annotation.width, equals(4.0));
      });

      test('sampleAnnotations returns list of annotations', () {
        final annotations = TestFixtures.sampleAnnotations;

        expect(annotations, isNotEmpty);
        expect(annotations.length, equals(2));
        expect(annotations.first.id, equals('ann_1'));
        expect(annotations[1].id, equals('ann_2'));
      });
    });

    group('Edge Cases', () {
      test('handles very small point values', () {
        final annotation = Annotation(
          id: 'ann_small',
          type: 'draw',
          color: '#000000',
          width: 0.1,
          points: [0.00001, 0.00001, 0.00002, 0.00002],
          page: 1,
        );

        expect(annotation.points![0], closeTo(0.00001, 0.000001));
      });

      test('handles point values at boundaries', () {
        final annotation = Annotation(
          id: 'ann_bounds',
          type: 'draw',
          color: '#000000',
          width: 2.0,
          points: [0.0, 0.0, 1.0, 1.0],
          page: 1,
        );

        expect(annotation.points![0], equals(0.0));
        expect(annotation.points![2], equals(1.0));
      });

      test('handles coordinates at boundaries', () {
        final annotation = Annotation(
          id: 'ann_coords',
          type: 'text',
          color: '#000000',
          width: 12.0,
          text: 'Corner',
          x: 0.0,
          y: 0.0,
          page: 1,
        );

        expect(annotation.x, equals(0.0));
        expect(annotation.y, equals(0.0));
      });
    });
  });
}
