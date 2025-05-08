import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../viewmodels/article_view_model.dart';
import '../screens/custom_topic_screen.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  
  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(context, AppConstants.categoryMixed),
              _buildCategoryChip(context, AppConstants.categoryScience),
              _buildCategoryChip(context, AppConstants.categoryHistory),
              _buildCategoryChip(context, AppConstants.categoryTechnology),
              _buildCategoryChip(context, AppConstants.categoryCulture),
              _buildCustomCategoryChip(context),
            ],
          ),
        ),
        
        // Özel kategori seçiliyse ve özel konu varsa göster
        if (selectedCategory == AppConstants.categoryCustom)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.topic, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer<ArticleViewModel>(
                    builder: (context, viewModel, child) {
                      return Text(
                        'Seçilen Konu: ${viewModel.selectedCustomTopic}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  onPressed: () => _navigateToCustomTopicScreen(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Konuyu Değiştir',
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildCategoryChip(BuildContext context, String category) {
    final isSelected = selectedCategory == category;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onCategorySelected(category);
          }
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        selectedColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isSelected ? 3 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.black45,
      ),
    );
  }
  
  Widget _buildCustomCategoryChip(BuildContext context) {
    final isSelected = selectedCategory == AppConstants.categoryCustom;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          Icons.topic,
          size: 18,
          color: isSelected ? Colors.white : Colors.blue.shade700,
        ),
        label: Text(AppConstants.categoryCustom),
        onPressed: () {
          if (isSelected) {
            _navigateToCustomTopicScreen(context);
          } else {
            onCategorySelected(AppConstants.categoryCustom);
          }
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: isSelected ? 3 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.black45,
        surfaceTintColor: isSelected ? Colors.blue.shade700 : null,
      ),
    );
  }
  
  void _navigateToCustomTopicScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomTopicScreen()),
    );
  }
} 