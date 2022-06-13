// Package imports:
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

enum FilterGroupType {
  single,
  multiple,
}

class FilterGroup extends Equatable {
  const FilterGroup({
    required this.groupType,
    required this.filterItems,
  });

  final FilterGroupType groupType;
  final List<FilterItem> filterItems;

  @override
  List<Object?> get props => [filterItems, groupType];

  @override
  String toString() => '$groupType: $filterItems';
}

FilterGroupType? _getGroupType(List<String> value) {
  if (value.isEmpty) return null;
  if (value.length == 1) return FilterGroupType.single;

  return FilterGroupType.multiple;
}

FilterGroup? stringToFilterGroup(String value) {
  //TODO: handle invalid format?
  if (value.isEmpty) return null;
  final tags = value.split(' ');
  final groupType = _getGroupType(tags);

  if (groupType == null) return null;

  return FilterGroup(
      groupType: groupType,
      filterItems: tags
          .map((e) => _stringToFilterItem(e, groupType))
          .whereNotNull()
          .toList());
}

class FilterItem extends Equatable {
  const FilterItem({
    required this.tag,
    required this.operator,
  });

  final String tag;
  final FilterOperator operator;

  @override
  List<Object?> get props => [tag, operator];

  @override
  String toString() => '${operator.toString().split('.').last}.$tag';
}

FilterOperator _stringToFilterOperator(String value) {
  switch (value) {
    case '-':
      return FilterOperator.not;
    case '~':
      return FilterOperator.or;
    default:
      return FilterOperator.none;
  }
}

String _stripFilterOperator(String value, FilterOperator operator) {
  switch (operator) {
    case FilterOperator.not:
    case FilterOperator.or:
      return value.substring(1);
    default:
      return value;
  }
}

// ignore: unnecessary_string_interpolations
String _getFirstCharacter(String value) => value == '' ? '' : '${value[0]}';

FilterItem? _stringToFilterItem(String value, FilterGroupType groupType) {
  if (value.isEmpty) return null;
  final firstChar = _getFirstCharacter(value);
  final operator = _stringToFilterOperator(firstChar);
  final tag = _stripFilterOperator(value, operator);

  if (groupType == FilterGroupType.single) {
    return FilterItem(
      tag: tag,
      operator: FilterOperator.none,
    );
  }

  return FilterItem(
    tag: tag,
    operator: operator,
  );
}

enum FilterOperator {
  none,
  not,
  or,
}
