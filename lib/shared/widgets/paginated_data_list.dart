import 'package:flutter/material.dart';
import '../../models/sensor_data.dart';
import 'dart:math' as math;

class PaginatedDataList extends StatefulWidget {
  final List<SensorData> data;
  final SensorMetric metric;
  final Color primaryColor;

  const PaginatedDataList({
    Key? key,
    required this.data,
    required this.metric,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<PaginatedDataList> createState() => _PaginatedDataListState();
}

class _PaginatedDataListState extends State<PaginatedDataList> {
  static const int _itemsPerPage = 15;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PaginatedDataList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-navigate to the last page when new data arrives
    if (widget.data.length > oldWidget.data.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final maxPage = _getMaxPage();
        if (_currentPage != maxPage) {
          setState(() {
            _currentPage = maxPage;
          });
        }
      });
    }
  }

  int _getMaxPage() {
    if (widget.data.isEmpty) return 0;
    
    return ((widget.data.length - 1) / _itemsPerPage).floor();
  }

  List<SensorData> _getCurrentPageData() {
    if (widget.data.isEmpty) return [];
    
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, widget.data.length);

    return widget.data.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    final maxPage = _getMaxPage();
    if (page >= 0 && page <= maxPage) {
      setState(() {
        _currentPage = page;
      });
      // Scroll to top of the list when changing pages
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildDataList(),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currentPageData = _getCurrentPageData();
    final stats = _calculateQuickStats(currentPageData);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: widget.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Data Feed',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: widget.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat('Total Records', _getFilteredDataCount().toDouble()),
              _buildQuickStat('Latest', stats['latest']!),
              _buildQuickStat('Page Average', stats['average']!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, double value) {
    String displayValue;
    
    if (label == 'Total Records') {
      displayValue = value.toInt().toString();
    } else {
      displayValue = value.toStringAsFixed(1);
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: TextStyle(
            color: widget.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDataList() {
    final currentPageData = _getCurrentPageData();
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: currentPageData.length,
      itemBuilder: (context, index) {
        final data = currentPageData[index];
        final value = widget.metric.getValue(data);
        final globalIndex = (_currentPage * _itemsPerPage) + index;
        final isLatest = globalIndex == widget.data.length - 1;
        
        return _buildDataItem(data, value, index, isLatest);
      },
    );
  }

  Widget _buildDataItem(SensorData data, double value, int index, bool isLatest) {
    final timestamp = data.parsedTimestamp;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLatest
            ? widget.primaryColor.withOpacity(0.15)
            : index % 2 == 0
                ? Colors.black.withOpacity(0.2)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isLatest
            ? Border.all(color: widget.primaryColor.withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: 30,
            child: Text(
              '${(_currentPage * _itemsPerPage) + index + 1}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Time
          SizedBox(
            width: 50,
            child: Text(
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isLatest
                    ? widget.primaryColor
                    : Colors.grey.shade300,
                fontSize: 11,
                fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Date
          SizedBox(
            width: 50,
            child: Text(
              '${timestamp.day}/${timestamp.month}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          
          // Value
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    color: isLatest ? Colors.white : Colors.grey.shade200,
                    fontSize: 13,
                    fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'monospace',
                  ),
                ),
                if (widget.metric.unit.isNotEmpty)
                  Text(
                    widget.metric.unit,
                    style: TextStyle(
                      color: widget.primaryColor.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLatest 
                  ? widget.primaryColor 
                  : widget.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final maxPage = _getMaxPage();
    final totalPages = maxPage + 1;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(
            color: widget.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Page ${_currentPage + 1} of $totalPages (${widget.data.length} total)',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          
          // Navigation buttons
          Row(
            children: [
              _buildPageButton(
                icon: Icons.first_page,
                onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
              ),
              const SizedBox(width: 4),
              _buildPageButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
              ),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage < maxPage ? () => _goToPage(_currentPage + 1) : null,
              ),
              const SizedBox(width: 4),
              _buildPageButton(
                icon: Icons.last_page,
                onPressed: _currentPage < maxPage ? () => _goToPage(maxPage) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onPressed != null
              ? widget.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onPressed != null
                ? widget.primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: onPressed != null
              ? widget.primaryColor
              : Colors.grey.withOpacity(0.5),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              color: widget.primaryColor.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(
                color: widget.primaryColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilteredDataCount() {
    return widget.data.length;
  }

  Map<String, double> _calculateQuickStats(List<SensorData> pageData) {
    if (pageData.isEmpty) {
      return {'latest': 0.0, 'average': 0.0};
    }

    final values = pageData.map((data) => widget.metric.getValue(data)).toList();
    final latest = widget.metric.getValue(widget.data.last);
    final average = values.reduce((a, b) => a + b) / values.length;

    return {
      'latest': latest,
      'average': average,
    };
  }
}
