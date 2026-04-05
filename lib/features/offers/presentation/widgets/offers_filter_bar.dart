import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/offers_bloc.dart';

class OffersFilterBar extends StatefulWidget {
  const OffersFilterBar({super.key});

  @override
  State<OffersFilterBar> createState() => _OffersFilterBarState();
}

class _OffersFilterBarState extends State<OffersFilterBar> {
  String? _selectedTradeType;
  String? _selectedCrypto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Buy'),
                    selected: _selectedTradeType == 'BUY',
                    onSelected: (v) {
                      setState(() {
                        _selectedTradeType = v ? 'BUY' : null;
                      });
                      _applyFilter();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Sell'),
                    selected: _selectedTradeType == 'SELL',
                    onSelected: (v) {
                      setState(() {
                        _selectedTradeType = v ? 'SELL' : null;
                      });
                      _applyFilter();
                    },
                  ),
                  const SizedBox(width: 16),
                  FilterChip(
                    label: const Text('XMR'),
                    selected: _selectedCrypto == 'XMR',
                    onSelected: (v) {
                      setState(() {
                        _selectedCrypto = v ? 'XMR' : null;
                      });
                      _applyFilter();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('BTC'),
                    selected: _selectedCrypto == 'BTC',
                    onSelected: (v) {
                      setState(() {
                        _selectedCrypto = v ? 'BTC' : null;
                      });
                      _applyFilter();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    context.read<OffersBloc>().add(OffersFilterChanged(
          tradeType: _selectedTradeType,
          cryptoCurrency: _selectedCrypto,
        ));
  }
}
