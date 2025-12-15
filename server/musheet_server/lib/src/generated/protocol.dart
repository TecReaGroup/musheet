/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'annotation.dart' as _i3;
import 'application.dart' as _i4;
import 'dto/auth_result.dart' as _i5;
import 'dto/avatar_upload_result.dart' as _i6;
import 'dto/dashboard_stats.dart' as _i7;
import 'dto/delete_user_data_result.dart' as _i8;
import 'dto/file_upload_result.dart' as _i9;
import 'dto/public_user_profile.dart' as _i10;
import 'dto/score_sync_result.dart' as _i11;
import 'dto/team_info.dart' as _i12;
import 'dto/team_member_info.dart' as _i13;
import 'dto/team_summary.dart' as _i14;
import 'dto/team_with_role.dart' as _i15;
import 'dto/user_info.dart' as _i16;
import 'dto/user_profile.dart' as _i17;
import 'instrument_score.dart' as _i18;
import 'score.dart' as _i19;
import 'setlist.dart' as _i20;
import 'setlist_score.dart' as _i21;
import 'team.dart' as _i22;
import 'team_annotation.dart' as _i23;
import 'team_member.dart' as _i24;
import 'team_score.dart' as _i25;
import 'team_setlist.dart' as _i26;
import 'user.dart' as _i27;
import 'user_app_data.dart' as _i28;
import 'user_storage.dart' as _i29;
import 'package:musheet_server/src/generated/dto/user_info.dart' as _i30;
import 'package:musheet_server/src/generated/dto/team_summary.dart' as _i31;
import 'package:musheet_server/src/generated/application.dart' as _i32;
import 'package:musheet_server/src/generated/score.dart' as _i33;
import 'package:musheet_server/src/generated/instrument_score.dart' as _i34;
import 'package:musheet_server/src/generated/annotation.dart' as _i35;
import 'package:musheet_server/src/generated/setlist.dart' as _i36;
import 'package:musheet_server/src/generated/setlist_score.dart' as _i37;
import 'package:musheet_server/src/generated/team_annotation.dart' as _i38;
import 'package:musheet_server/src/generated/team.dart' as _i39;
import 'package:musheet_server/src/generated/dto/team_member_info.dart' as _i40;
import 'package:musheet_server/src/generated/dto/team_with_role.dart' as _i41;
export 'annotation.dart';
export 'application.dart';
export 'dto/auth_result.dart';
export 'dto/avatar_upload_result.dart';
export 'dto/dashboard_stats.dart';
export 'dto/delete_user_data_result.dart';
export 'dto/file_upload_result.dart';
export 'dto/public_user_profile.dart';
export 'dto/score_sync_result.dart';
export 'dto/team_info.dart';
export 'dto/team_member_info.dart';
export 'dto/team_summary.dart';
export 'dto/team_with_role.dart';
export 'dto/user_info.dart';
export 'dto/user_profile.dart';
export 'instrument_score.dart';
export 'score.dart';
export 'setlist.dart';
export 'setlist_score.dart';
export 'team.dart';
export 'team_annotation.dart';
export 'team_member.dart';
export 'team_score.dart';
export 'team_setlist.dart';
export 'user.dart';
export 'user_app_data.dart';
export 'user_storage.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'annotations',
      dartName: 'Annotation',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'annotations_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'instrumentScoreId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'pageNumber',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'data',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'positionX',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'positionY',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'width',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'height',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'color',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'vectorClock',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'annotations_fk_0',
          columns: ['instrumentScoreId'],
          referenceTable: 'instrument_scores',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'annotations_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'annotation_inst_score_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'instrumentScoreId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'applications',
      dartName: 'Application',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'applications_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'appId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'iconPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'applications_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'app_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'instrument_scores',
      dartName: 'InstrumentScore',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'instrument_scores_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'scoreId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'instrumentName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'pdfPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'pdfHash',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'orderIndex',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'instrument_scores_fk_0',
          columns: ['scoreId'],
          referenceTable: 'scores',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'instrument_scores_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'instrument_score_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'scoreId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'scores',
      dartName: 'Score',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'scores_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'composer',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'bpm',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'version',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'syncStatus',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'scores_fk_0',
          columns: ['userId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'scores_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'score_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'score_user_updated_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'setlist_scores',
      dartName: 'SetlistScore',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'setlist_scores_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'setlistId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'scoreId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'orderIndex',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'setlist_scores_fk_0',
          columns: ['setlistId'],
          referenceTable: 'setlists',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'setlist_scores_fk_1',
          columns: ['scoreId'],
          referenceTable: 'scores',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'setlist_scores_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'setlist_score_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'setlistId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'setlists',
      dartName: 'Setlist',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'setlists_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'setlists_fk_0',
          columns: ['userId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'setlists_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'setlist_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'team_annotations',
      dartName: 'TeamAnnotation',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'team_annotations_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'teamScoreId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'instrumentScoreId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'pageNumber',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'data',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'positionX',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'positionY',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _i2.ColumnDefinition(
          name: 'createdBy',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'updatedBy',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'vectorClock',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'team_annotations_fk_0',
          columns: ['teamScoreId'],
          referenceTable: 'team_scores',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'team_annotations_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'team_annotation_team_score_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamScoreId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'team_members',
      dartName: 'TeamMember',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'team_members_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'teamId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'joinedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'team_members_fk_0',
          columns: ['teamId'],
          referenceTable: 'teams',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'team_members_fk_1',
          columns: ['userId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'team_members_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'team_member_team_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'team_member_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'team_member_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'team_scores',
      dartName: 'TeamScore',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'team_scores_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'teamId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'scoreId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sharedById',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sharedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'team_scores_fk_0',
          columns: ['teamId'],
          referenceTable: 'teams',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'team_scores_fk_1',
          columns: ['scoreId'],
          referenceTable: 'scores',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'team_scores_fk_2',
          columns: ['sharedById'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'team_scores_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'team_score_team_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'team_score_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'scoreId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'team_setlists',
      dartName: 'TeamSetlist',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'team_setlists_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'teamId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'setlistId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sharedById',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sharedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'team_setlists_fk_0',
          columns: ['teamId'],
          referenceTable: 'teams',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'team_setlists_fk_1',
          columns: ['setlistId'],
          referenceTable: 'setlists',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'team_setlists_fk_2',
          columns: ['sharedById'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'team_setlists_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'team_setlist_team_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'team_setlist_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'teamId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'setlistId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'teams',
      dartName: 'Team',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'teams_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'inviteCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdById',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'teams_fk_0',
          columns: ['createdById'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'teams_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'team_invite_code_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'inviteCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_app_data',
      dartName: 'UserAppData',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_app_data_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'applicationId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'preferences',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'settings',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'user_app_data_fk_0',
          columns: ['userId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_app_data_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_app_data_user_app_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'applicationId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_storage',
      dartName: 'UserStorage',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_storage_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'usedBytes',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'quotaBytes',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'lastCalculatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'user_storage_fk_0',
          columns: ['userId'],
          referenceTable: 'users',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_storage_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_storage_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'users',
      dartName: 'User',
      schema: 'public',
      module: 'musheet',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'users_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'username',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'passwordHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'avatarPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'bio',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'preferredInstrument',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'isAdmin',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'isDisabled',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'mustChangePassword',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'lastLoginAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'users_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_username_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'username',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i3.Annotation) {
      return _i3.Annotation.fromJson(data) as T;
    }
    if (t == _i4.Application) {
      return _i4.Application.fromJson(data) as T;
    }
    if (t == _i5.AuthResult) {
      return _i5.AuthResult.fromJson(data) as T;
    }
    if (t == _i6.AvatarUploadResult) {
      return _i6.AvatarUploadResult.fromJson(data) as T;
    }
    if (t == _i7.DashboardStats) {
      return _i7.DashboardStats.fromJson(data) as T;
    }
    if (t == _i8.DeleteUserDataResult) {
      return _i8.DeleteUserDataResult.fromJson(data) as T;
    }
    if (t == _i9.FileUploadResult) {
      return _i9.FileUploadResult.fromJson(data) as T;
    }
    if (t == _i10.PublicUserProfile) {
      return _i10.PublicUserProfile.fromJson(data) as T;
    }
    if (t == _i11.ScoreSyncResult) {
      return _i11.ScoreSyncResult.fromJson(data) as T;
    }
    if (t == _i12.TeamInfo) {
      return _i12.TeamInfo.fromJson(data) as T;
    }
    if (t == _i13.TeamMemberInfo) {
      return _i13.TeamMemberInfo.fromJson(data) as T;
    }
    if (t == _i14.TeamSummary) {
      return _i14.TeamSummary.fromJson(data) as T;
    }
    if (t == _i15.TeamWithRole) {
      return _i15.TeamWithRole.fromJson(data) as T;
    }
    if (t == _i16.UserInfo) {
      return _i16.UserInfo.fromJson(data) as T;
    }
    if (t == _i17.UserProfile) {
      return _i17.UserProfile.fromJson(data) as T;
    }
    if (t == _i18.InstrumentScore) {
      return _i18.InstrumentScore.fromJson(data) as T;
    }
    if (t == _i19.Score) {
      return _i19.Score.fromJson(data) as T;
    }
    if (t == _i20.Setlist) {
      return _i20.Setlist.fromJson(data) as T;
    }
    if (t == _i21.SetlistScore) {
      return _i21.SetlistScore.fromJson(data) as T;
    }
    if (t == _i22.Team) {
      return _i22.Team.fromJson(data) as T;
    }
    if (t == _i23.TeamAnnotation) {
      return _i23.TeamAnnotation.fromJson(data) as T;
    }
    if (t == _i24.TeamMember) {
      return _i24.TeamMember.fromJson(data) as T;
    }
    if (t == _i25.TeamScore) {
      return _i25.TeamScore.fromJson(data) as T;
    }
    if (t == _i26.TeamSetlist) {
      return _i26.TeamSetlist.fromJson(data) as T;
    }
    if (t == _i27.User) {
      return _i27.User.fromJson(data) as T;
    }
    if (t == _i28.UserAppData) {
      return _i28.UserAppData.fromJson(data) as T;
    }
    if (t == _i29.UserStorage) {
      return _i29.UserStorage.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.Annotation?>()) {
      return (data != null ? _i3.Annotation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Application?>()) {
      return (data != null ? _i4.Application.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AuthResult?>()) {
      return (data != null ? _i5.AuthResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AvatarUploadResult?>()) {
      return (data != null ? _i6.AvatarUploadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.DashboardStats?>()) {
      return (data != null ? _i7.DashboardStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.DeleteUserDataResult?>()) {
      return (data != null ? _i8.DeleteUserDataResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.FileUploadResult?>()) {
      return (data != null ? _i9.FileUploadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.PublicUserProfile?>()) {
      return (data != null ? _i10.PublicUserProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.ScoreSyncResult?>()) {
      return (data != null ? _i11.ScoreSyncResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.TeamInfo?>()) {
      return (data != null ? _i12.TeamInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.TeamMemberInfo?>()) {
      return (data != null ? _i13.TeamMemberInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.TeamSummary?>()) {
      return (data != null ? _i14.TeamSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.TeamWithRole?>()) {
      return (data != null ? _i15.TeamWithRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.UserInfo?>()) {
      return (data != null ? _i16.UserInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.UserProfile?>()) {
      return (data != null ? _i17.UserProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.InstrumentScore?>()) {
      return (data != null ? _i18.InstrumentScore.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.Score?>()) {
      return (data != null ? _i19.Score.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.Setlist?>()) {
      return (data != null ? _i20.Setlist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.SetlistScore?>()) {
      return (data != null ? _i21.SetlistScore.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.Team?>()) {
      return (data != null ? _i22.Team.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.TeamAnnotation?>()) {
      return (data != null ? _i23.TeamAnnotation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.TeamMember?>()) {
      return (data != null ? _i24.TeamMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.TeamScore?>()) {
      return (data != null ? _i25.TeamScore.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.TeamSetlist?>()) {
      return (data != null ? _i26.TeamSetlist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.User?>()) {
      return (data != null ? _i27.User.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.UserAppData?>()) {
      return (data != null ? _i28.UserAppData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.UserStorage?>()) {
      return (data != null ? _i29.UserStorage.fromJson(data) : null) as T;
    }
    if (t == List<_i14.TeamSummary>) {
      return (data as List)
              .map((e) => deserialize<_i14.TeamSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i12.TeamInfo>) {
      return (data as List).map((e) => deserialize<_i12.TeamInfo>(e)).toList()
          as T;
    }
    if (t == List<_i30.UserInfo>) {
      return (data as List).map((e) => deserialize<_i30.UserInfo>(e)).toList()
          as T;
    }
    if (t == List<_i31.TeamSummary>) {
      return (data as List)
              .map((e) => deserialize<_i31.TeamSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.Application>) {
      return (data as List)
              .map((e) => deserialize<_i32.Application>(e))
              .toList()
          as T;
    }
    if (t == List<_i33.Score>) {
      return (data as List).map((e) => deserialize<_i33.Score>(e)).toList()
          as T;
    }
    if (t == List<_i34.InstrumentScore>) {
      return (data as List)
              .map((e) => deserialize<_i34.InstrumentScore>(e))
              .toList()
          as T;
    }
    if (t == List<_i35.Annotation>) {
      return (data as List).map((e) => deserialize<_i35.Annotation>(e)).toList()
          as T;
    }
    if (t == List<_i36.Setlist>) {
      return (data as List).map((e) => deserialize<_i36.Setlist>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i37.SetlistScore>) {
      return (data as List)
              .map((e) => deserialize<_i37.SetlistScore>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == List<_i38.TeamAnnotation>) {
      return (data as List)
              .map((e) => deserialize<_i38.TeamAnnotation>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.Team>) {
      return (data as List).map((e) => deserialize<_i39.Team>(e)).toList() as T;
    }
    if (t == List<_i40.TeamMemberInfo>) {
      return (data as List)
              .map((e) => deserialize<_i40.TeamMemberInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i41.TeamWithRole>) {
      return (data as List)
              .map((e) => deserialize<_i41.TeamWithRole>(e))
              .toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.Annotation => 'Annotation',
      _i4.Application => 'Application',
      _i5.AuthResult => 'AuthResult',
      _i6.AvatarUploadResult => 'AvatarUploadResult',
      _i7.DashboardStats => 'DashboardStats',
      _i8.DeleteUserDataResult => 'DeleteUserDataResult',
      _i9.FileUploadResult => 'FileUploadResult',
      _i10.PublicUserProfile => 'PublicUserProfile',
      _i11.ScoreSyncResult => 'ScoreSyncResult',
      _i12.TeamInfo => 'TeamInfo',
      _i13.TeamMemberInfo => 'TeamMemberInfo',
      _i14.TeamSummary => 'TeamSummary',
      _i15.TeamWithRole => 'TeamWithRole',
      _i16.UserInfo => 'UserInfo',
      _i17.UserProfile => 'UserProfile',
      _i18.InstrumentScore => 'InstrumentScore',
      _i19.Score => 'Score',
      _i20.Setlist => 'Setlist',
      _i21.SetlistScore => 'SetlistScore',
      _i22.Team => 'Team',
      _i23.TeamAnnotation => 'TeamAnnotation',
      _i24.TeamMember => 'TeamMember',
      _i25.TeamScore => 'TeamScore',
      _i26.TeamSetlist => 'TeamSetlist',
      _i27.User => 'User',
      _i28.UserAppData => 'UserAppData',
      _i29.UserStorage => 'UserStorage',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('musheet.', '');
    }

    switch (data) {
      case _i3.Annotation():
        return 'Annotation';
      case _i4.Application():
        return 'Application';
      case _i5.AuthResult():
        return 'AuthResult';
      case _i6.AvatarUploadResult():
        return 'AvatarUploadResult';
      case _i7.DashboardStats():
        return 'DashboardStats';
      case _i8.DeleteUserDataResult():
        return 'DeleteUserDataResult';
      case _i9.FileUploadResult():
        return 'FileUploadResult';
      case _i10.PublicUserProfile():
        return 'PublicUserProfile';
      case _i11.ScoreSyncResult():
        return 'ScoreSyncResult';
      case _i12.TeamInfo():
        return 'TeamInfo';
      case _i13.TeamMemberInfo():
        return 'TeamMemberInfo';
      case _i14.TeamSummary():
        return 'TeamSummary';
      case _i15.TeamWithRole():
        return 'TeamWithRole';
      case _i16.UserInfo():
        return 'UserInfo';
      case _i17.UserProfile():
        return 'UserProfile';
      case _i18.InstrumentScore():
        return 'InstrumentScore';
      case _i19.Score():
        return 'Score';
      case _i20.Setlist():
        return 'Setlist';
      case _i21.SetlistScore():
        return 'SetlistScore';
      case _i22.Team():
        return 'Team';
      case _i23.TeamAnnotation():
        return 'TeamAnnotation';
      case _i24.TeamMember():
        return 'TeamMember';
      case _i25.TeamScore():
        return 'TeamScore';
      case _i26.TeamSetlist():
        return 'TeamSetlist';
      case _i27.User():
        return 'User';
      case _i28.UserAppData():
        return 'UserAppData';
      case _i29.UserStorage():
        return 'UserStorage';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Annotation') {
      return deserialize<_i3.Annotation>(data['data']);
    }
    if (dataClassName == 'Application') {
      return deserialize<_i4.Application>(data['data']);
    }
    if (dataClassName == 'AuthResult') {
      return deserialize<_i5.AuthResult>(data['data']);
    }
    if (dataClassName == 'AvatarUploadResult') {
      return deserialize<_i6.AvatarUploadResult>(data['data']);
    }
    if (dataClassName == 'DashboardStats') {
      return deserialize<_i7.DashboardStats>(data['data']);
    }
    if (dataClassName == 'DeleteUserDataResult') {
      return deserialize<_i8.DeleteUserDataResult>(data['data']);
    }
    if (dataClassName == 'FileUploadResult') {
      return deserialize<_i9.FileUploadResult>(data['data']);
    }
    if (dataClassName == 'PublicUserProfile') {
      return deserialize<_i10.PublicUserProfile>(data['data']);
    }
    if (dataClassName == 'ScoreSyncResult') {
      return deserialize<_i11.ScoreSyncResult>(data['data']);
    }
    if (dataClassName == 'TeamInfo') {
      return deserialize<_i12.TeamInfo>(data['data']);
    }
    if (dataClassName == 'TeamMemberInfo') {
      return deserialize<_i13.TeamMemberInfo>(data['data']);
    }
    if (dataClassName == 'TeamSummary') {
      return deserialize<_i14.TeamSummary>(data['data']);
    }
    if (dataClassName == 'TeamWithRole') {
      return deserialize<_i15.TeamWithRole>(data['data']);
    }
    if (dataClassName == 'UserInfo') {
      return deserialize<_i16.UserInfo>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_i17.UserProfile>(data['data']);
    }
    if (dataClassName == 'InstrumentScore') {
      return deserialize<_i18.InstrumentScore>(data['data']);
    }
    if (dataClassName == 'Score') {
      return deserialize<_i19.Score>(data['data']);
    }
    if (dataClassName == 'Setlist') {
      return deserialize<_i20.Setlist>(data['data']);
    }
    if (dataClassName == 'SetlistScore') {
      return deserialize<_i21.SetlistScore>(data['data']);
    }
    if (dataClassName == 'Team') {
      return deserialize<_i22.Team>(data['data']);
    }
    if (dataClassName == 'TeamAnnotation') {
      return deserialize<_i23.TeamAnnotation>(data['data']);
    }
    if (dataClassName == 'TeamMember') {
      return deserialize<_i24.TeamMember>(data['data']);
    }
    if (dataClassName == 'TeamScore') {
      return deserialize<_i25.TeamScore>(data['data']);
    }
    if (dataClassName == 'TeamSetlist') {
      return deserialize<_i26.TeamSetlist>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_i27.User>(data['data']);
    }
    if (dataClassName == 'UserAppData') {
      return deserialize<_i28.UserAppData>(data['data']);
    }
    if (dataClassName == 'UserStorage') {
      return deserialize<_i29.UserStorage>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i3.Annotation:
        return _i3.Annotation.t;
      case _i4.Application:
        return _i4.Application.t;
      case _i18.InstrumentScore:
        return _i18.InstrumentScore.t;
      case _i19.Score:
        return _i19.Score.t;
      case _i20.Setlist:
        return _i20.Setlist.t;
      case _i21.SetlistScore:
        return _i21.SetlistScore.t;
      case _i22.Team:
        return _i22.Team.t;
      case _i23.TeamAnnotation:
        return _i23.TeamAnnotation.t;
      case _i24.TeamMember:
        return _i24.TeamMember.t;
      case _i25.TeamScore:
        return _i25.TeamScore.t;
      case _i26.TeamSetlist:
        return _i26.TeamSetlist.t;
      case _i27.User:
        return _i27.User.t;
      case _i28.UserAppData:
        return _i28.UserAppData.t;
      case _i29.UserStorage:
        return _i29.UserStorage.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'musheet';
}
