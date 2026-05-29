import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trading/domain/entities/offer.dart';
import '../../domain/repositories/search_repository.dart';
import '../bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _coin;
  String? _fiat;
  OfferType? _type;
  String _sort = 'price';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  SearchQuery _query() => SearchQuery(
        query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        coin: _coin,
        fiatCurrency: _fiat,
        type: _type,
        sortBy: _sort,
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return BlocProvider<SearchBloc>(
      create: (_) =>
          sl<SearchBloc>()..add(SearchQueryChanged(const SearchQuery())),
      child: Builder(builder: (BuildContext context) {
        void run() => context.read<SearchBloc>().add(SearchQueryChanged(_query()));
        return Scaffold(
          appBar: AppBar(title: Text(l.search)),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: l.search_hint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (_) => run(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                      _SmallDropdown<String?>(
                        value: _coin,
                        hint: l.coin,
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(value: null, child: Text('Any coin')),
                          ...AppConstants.supportedCoins.map(
                              (c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                        ],
                        onChanged: (v) {
                          setState(() => _coin = v);
                          run();
                        },
                      ),
                      _SmallDropdown<String?>(
                        value: _fiat,
                        hint: l.currency,
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(value: null, child: Text('Any currency')),
                          ...AppConstants.supportedFiatCurrencies.map(
                              (c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                        ],
                        onChanged: (v) {
                          setState(() => _fiat = v);
                          run();
                        },
                      ),
                      _SmallDropdown<OfferType?>(
                        value: _type,
                        hint: 'Type',
                        items: const <DropdownMenuItem<OfferType?>>[
                          DropdownMenuItem<OfferType?>(value: null, child: Text('Any type')),
                          DropdownMenuItem<OfferType?>(value: OfferType.sell, child: Text('Sell')),
                          DropdownMenuItem<OfferType?>(value: OfferType.buy, child: Text('Buy')),
                        ],
                        onChanged: (v) {
                          setState(() => _type = v);
                          run();
                        },
                      ),
                      _SmallDropdown<String>(
                        value: _sort,
                        hint: 'Sort',
                        items: <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(value: 'price', child: Text(l.sortByPrice)),
                          DropdownMenuItem<String>(value: 'reputation', child: Text(l.sortByReputation)),
                          DropdownMenuItem<String>(value: 'recency', child: Text(l.sortByRecency)),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _sort = v);
                          run();
                        },
                      ),
                    ]),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (BuildContext context, SearchState state) {
                    if (state is SearchLoading || state is SearchInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is SearchErrorState) {
                      return Center(child: Text(state.failure.message));
                    }
                    final List<Offer> offers = (state as SearchLoaded).offers;
                    if (offers.isEmpty) {
                      return const Center(child: Text('No matching offers'));
                    }
                    return ListView.builder(
                      itemCount: offers.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Offer o = offers[i];
                        return ListTile(
                          title: Text('${o.ownerUsername} • ${o.paymentMethod}'),
                          subtitle: Text(
                              '${o.coin} • ${o.priceEquation} ${o.fiatCurrency} • '
                              '${Formatters.fiat(o.minAmount, o.fiatCurrency)}–${Formatters.fiat(o.maxAmount, o.fiatCurrency)}'),
                          trailing: Text(o.country ?? ''),
                          onTap: () => context.push('/offers/${o.id}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SmallDropdown<T> extends StatelessWidget {
  const _SmallDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint),
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
