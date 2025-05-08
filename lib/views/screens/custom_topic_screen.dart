import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/article_view_model.dart';
import '../../utils/constants.dart';

class CustomTopicScreen extends StatefulWidget {
  const CustomTopicScreen({super.key});

  @override
  State<CustomTopicScreen> createState() => _CustomTopicScreenState();
}

class _CustomTopicScreenState extends State<CustomTopicScreen> {
  final TextEditingController _topicController = TextEditingController();
  final FocusNode _topicFocusNode = FocusNode();
  bool _isEditing = false;
  
  @override
  void dispose() {
    _topicController.dispose();
    _topicFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Özel Konular'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ArticleViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // Üst bilgi kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade600,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İlgilendiğin Konular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İstediğin konularda bilgiler al. Futbol takımı, şehir, müzik tarzı veya ilgilendiğin herhangi bir konu hakkında bilgi edinebilirsin.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Yeni konu ekleme alanı
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _topicController,
                        focusNode: _topicFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Yeni bir konu ekle...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          _addTopic(viewModel, value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _addTopic(viewModel, _topicController.text);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ekle'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Mevcut konular listesi
              Expanded(
                child: viewModel.customTopics.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: viewModel.customTopics.length,
                        itemBuilder: (context, index) {
                          final topic = viewModel.customTopics[index];
                          final isSelected = topic == viewModel.selectedCustomTopic;
                          
                          return Card(
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: isSelected 
                                ? BorderSide(color: Colors.blue.shade700, width: 2)
                                : BorderSide.none,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                _selectTopic(viewModel, topic);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.topic,
                                      color: isSelected ? Colors.blue.shade700 : Colors.black54,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        topic,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        _removeTopic(viewModel, topic);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Boş durum widgetı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz özel konu eklemediniz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'İlgilendiğiniz konuları ekleyerek daha fazla bilgi alabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _topicFocusNode.requestFocus();
            },
            icon: const Icon(Icons.add),
            label: const Text('Konu Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Yeni konu ekleme işlemi
  void _addTopic(ArticleViewModel viewModel, String topic) {
    if (topic.trim().isEmpty) return;
    
    viewModel.addCustomTopic(topic.trim());
    _topicController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$topic eklendi'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Seç',
          onPressed: () {
            _selectTopic(viewModel, topic.trim());
          },
        ),
      ),
    );
  }
  
  // Konu seçme işlemi
  void _selectTopic(ArticleViewModel viewModel, String topic) {
    viewModel.changeCustomTopic(topic);
    
    Navigator.pop(context);
  }
  
  // Konu silme işlemi
  void _removeTopic(ArticleViewModel viewModel, String topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuyu Sil'),
        content: Text('$topic konusunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeCustomTopic(topic);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$topic silindi'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 