import 'package:equatable/equatable.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

const Object _unset = Object();

/// Filter for searching transactions. All fields are optional and combine with
/// AND. [query] matches the transaction note.
class SearchCriteria extends Equatable {
  const SearchCriteria({
    this.query = '',
    this.type,
    this.categoryId,
    this.from,
    this.to,
    this.minAmount,
    this.maxAmount,
  });

  final String query;
  final TransactionType? type;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;
  final double? minAmount;
  final double? maxAmount;

  bool get hasActiveFilters =>
      type != null ||
      categoryId != null ||
      from != null ||
      minAmount != null ||
      maxAmount != null;

  SearchCriteria copyWith({
    String? query,
    Object? type = _unset,
    Object? categoryId = _unset,
    Object? from = _unset,
    Object? to = _unset,
    Object? minAmount = _unset,
    Object? maxAmount = _unset,
  }) {
    return SearchCriteria(
      query: query ?? this.query,
      type: identical(type, _unset) ? this.type : type as TransactionType?,
      categoryId:
          identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
      from: identical(from, _unset) ? this.from : from as DateTime?,
      to: identical(to, _unset) ? this.to : to as DateTime?,
      minAmount:
          identical(minAmount, _unset) ? this.minAmount : minAmount as double?,
      maxAmount:
          identical(maxAmount, _unset) ? this.maxAmount : maxAmount as double?,
    );
  }

  @override
  List<Object?> get props =>
      [query, type, categoryId, from, to, minAmount, maxAmount];
}
