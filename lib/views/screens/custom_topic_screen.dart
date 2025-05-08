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
                      'İstediğin Konuyu Keşfet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Futbol takımları, şehirler, müzik, tarih, bilim veya herhangi bir konu hakkında bilgi edinebilirsin. Sadece konuyu ekle ve keşfetmeye başla.',
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
                          hintText: 'Yeni bir konu ekle veya ara...',
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
              
              // Öneriler bölümü
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Önerilen Konular',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: viewModel.customTopics.map((topic) {
                        final isAlreadyAdded = viewModel.customTopics.contains(topic);
                        return ActionChip(
                          label: Text(topic),
                          avatar: Icon(
                            isAlreadyAdded ? Icons.check : Icons.add,
                            size: 16,
                          ),
                          backgroundColor: isAlreadyAdded 
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                          onPressed: () {
                            if (!isAlreadyAdded) {
                              _addTopic(viewModel, topic);
                            } else {
                              _selectTopic(viewModel, topic);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // Başlık
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Konularım',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${viewModel.customTopics.length})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    if (viewModel.customTopics.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          viewModel.customTopics.isEmpty 
                            ? 'Konu ekle' 
                            : 'Şimdi keşfet',
                          style: const TextStyle(fontSize: 14),
                        ),
                        onPressed: () {
                          if (viewModel.customTopics.isNotEmpty) {
                            if (viewModel.selectedCustomTopic.isEmpty) {
                              _selectTopic(viewModel, viewModel.customTopics.first);
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        },
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
                                      isSelected ? Icons.check_circle : Icons.topic,
                                      color: isSelected ? Colors.blue.shade700 : Colors.black54,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            topic,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                            ),
                                          ),
                                          if (isSelected)
                                            const Text(
                                              'Şu anda seçili',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        _removeTopic(viewModel, topic);
                                      },
                                      tooltip: 'Konuyu Sil',
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
              'İlgilendiğin konuları ekleyerek sadece o konularla ilgili bilgiler alabilirsin.',
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
          label: 'Göster',
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