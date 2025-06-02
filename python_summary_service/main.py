from flask import Flask, request, jsonify
from flask_cors import CORS
import wikipedia
import logging
import traceback
from typing import Optional

# Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # CORS'u etkinleştir

# Wikipedia dilini Türkçe olarak ayarla
wikipedia.set_lang("tr")

def clean_and_summarize_text(text: str, sentences: int = 4) -> str:
    """
    Verilen metni temizler ve özetler.
    
    Args:
        text: Özetlenecek metin
        sentences: Özet cümle sayısı (varsayılan 4)
    
    Returns:
        Özetlenmiş metin
    """
    if not text or len(text.strip()) == 0:
        return "Makale içeriği bulunamadı."
    
    # Metni cümlelere ayır
    sentences_list = text.replace('\n', ' ').split('.')
    
    # Boş cümleleri filtrele
    clean_sentences = [s.strip() for s in sentences_list if s.strip()]
    
    # İstenilen sayıda cümle al
    if len(clean_sentences) <= sentences:
        return '. '.join(clean_sentences) + '.'
    
    # İlk n cümleyi al
    summary_sentences = clean_sentences[:sentences]
    return '. '.join(summary_sentences) + '.'

@app.route('/health', methods=['GET'])
def health_check():
    """Servis sağlık kontrolü"""
    return jsonify({
        'status': 'healthy',
        'message': 'Python Wikipedia Özet Servisi çalışıyor'
    })

@app.route('/summarize', methods=['POST'])
def summarize_article():
    """
    Wikipedia makalesini özetler
    
    Expected JSON payload:
    {
        "content": "makale içeriği",
        "title": "makale başlığı (opsiyonel)",
        "sentences": 4 (opsiyonel, varsayılan 4)
    }
    """
    try:
        # Request verilerini al
        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'JSON verisi bulunamadı',
                'summary': 'Özet oluşturulamadı.'
            }), 400
        
        content = data.get('content', '')
        title = data.get('title', '')
        sentences = data.get('sentences', 4)
        
        logger.info(f"🐍 PYTHON SERVİSİ KULLANILIYOR - API MALİYETİ YOK!")
        logger.info(f"📄 Özet talebi alındı: başlık='{title}', içerik uzunluğu={len(content)}, cümle sayısı={sentences}")
        
        if not content:
            return jsonify({
                'error': 'Makale içeriği bulunamadı',
                'summary': 'Makale içeriği boş veya geçersiz.'
            }), 400
        
        # Metni özetle
        summary = clean_and_summarize_text(content, sentences)
        
        logger.info(f"✅ Özet başarıyla oluşturuldu: {len(summary)} karakter - PYTHON PAKETİ KULLANILDI!")
        logger.info(f"💰 API MALİYETİ: 0₺ (ÜCRETSIZ)")
        
        return jsonify({
            'success': True,
            'summary': summary,
            'original_length': len(content),
            'summary_length': len(summary),
            'sentences_count': sentences,
            'service_used': 'Python Wikipedia Package',
            'cost': '0₺ - ÜCRETSIZ'
        })
        
    except Exception as e:
        error_msg = f"Özet oluşturulurken hata: {str(e)}"
        logger.error(f"❌ {error_msg}\n{traceback.format_exc()}")
        
        return jsonify({
            'error': error_msg,
            'summary': 'Bu makalenin özeti şu anda mevcut değil. Lütfen daha sonra tekrar deneyin.'
        }), 500

@app.route('/search-and-summarize', methods=['POST'])
def search_and_summarize():
    """
    Wikipedia'da arama yapar ve bulunan makaleyi özetler
    
    Expected JSON payload:
    {
        "query": "arama sorgusu",
        "sentences": 4 (opsiyonel)
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'JSON verisi bulunamadı'
            }), 400
        
        query = data.get('query', '')
        sentences = data.get('sentences', 4)
        
        if not query:
            return jsonify({
                'error': 'Arama sorgusu bulunamadı'
            }), 400
        
        logger.info(f"Wikipedia arama talebi: '{query}'")
        
        # Wikipedia'da arama yap
        try:
            # Sayfa başlığını bul
            search_results = wikipedia.search(query, results=5)
            
            if not search_results:
                return jsonify({
                    'error': f"'{query}' için sonuç bulunamadı",
                    'summary': f"'{query}' konusu hakkında bilgi bulunamadı."
                })
            
            # İlk sonucu al
            page_title = search_results[0]
            
            # Sayfa içeriğini al
            page = wikipedia.page(page_title)
            content = page.content
            
            # Özet oluştur
            summary = clean_and_summarize_text(content, sentences)
            
            logger.info(f"Wikipedia sayfası bulundu ve özetlendi: '{page_title}'")
            
            return jsonify({
                'success': True,
                'title': page.title,
                'summary': summary,
                'url': page.url,
                'original_length': len(content),
                'summary_length': len(summary)
            })
            
        except wikipedia.DisambiguationError as e:
            # Belirsizlik durumunda ilk seçeneği al
            try:
                page = wikipedia.page(e.options[0])
                content = page.content
                summary = clean_and_summarize_text(content, sentences)
                
                logger.info(f"Belirsizlik çözüldü, sayfa bulundu: '{page.title}'")
                
                return jsonify({
                    'success': True,
                    'title': page.title,
                    'summary': summary,
                    'url': page.url,
                    'original_length': len(content),
                    'summary_length': len(summary),
                    'disambiguation_resolved': True
                })
            except Exception as inner_e:
                logger.error(f"Belirsizlik çözümü başarısız: {str(inner_e)}")
                return jsonify({
                    'error': f"Belirsizlik çözülemedi: {str(inner_e)}",
                    'summary': f"'{query}' konusu hakkında net bilgi bulunamadı."
                })
        
        except wikipedia.PageError:
            return jsonify({
                'error': f"'{query}' sayfası bulunamadı",
                'summary': f"'{query}' konusu hakkında sayfa bulunamadı."
            })
        
    except Exception as e:
        error_msg = f"Arama ve özetleme sırasında hata: {str(e)}"
        logger.error(f"{error_msg}\n{traceback.format_exc()}")
        
        return jsonify({
            'error': error_msg,
            'summary': 'Arama sırasında bir hata oluştu. Lütfen tekrar deneyin.'
        }), 500

@app.route('/random-summary', methods=['GET'])
def random_summary():
    """Rastgele bir Wikipedia makalesini özetler"""
    try:
        # Rastgele sayfa al
        random_title = wikipedia.random()
        page = wikipedia.page(random_title)
        
        # Özet oluştur
        summary = clean_and_summarize_text(page.content, 4)
        
        logger.info(f"Rastgele makale özetlendi: '{page.title}'")
        
        return jsonify({
            'success': True,
            'title': page.title,
            'summary': summary,
            'url': page.url,
            'content': page.content,
            'original_length': len(page.content),
            'summary_length': len(summary)
        })
        
    except Exception as e:
        error_msg = f"Rastgele makale özetleme hatası: {str(e)}"
        logger.error(f"{error_msg}\n{traceback.format_exc()}")
        
        return jsonify({
            'error': error_msg,
            'summary': 'Rastgele makale alınırken hata oluştu.'
        }), 500

if __name__ == '__main__':
    logger.info("Python Wikipedia Özet Servisi başlatılıyor...")
    app.run(host='0.0.0.0', port=5001, debug=True) 