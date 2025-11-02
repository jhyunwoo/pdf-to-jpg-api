from flask import Flask, request, jsonify
from pdf2image import convert_from_path
import requests
import os
import tempfile
import uuid
from io import BytesIO
from datetime import datetime
import logging

app = Flask(__name__)

# 환경 변수에서 설정 가져오기
ENV = os.getenv('FLASK_ENV', 'development')
PORT = int(os.getenv('PORT', 3000))
DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'

# 로깅 설정
if ENV == 'production':
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler('logs/app.log'),
            logging.StreamHandler()
        ]
    )
else:
    logging.basicConfig(level=logging.DEBUG)

logger = logging.getLogger(__name__)

# 임시 파일 저장 디렉토리
TEMP_DIR = tempfile.gettempdir()

def download_pdf_from_url(url):
    """
    URL에서 PDF 파일을 다운로드합니다.
    """
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        # Content-Type 확인 (선택적)
        content_type = response.headers.get('Content-Type', '')
        if 'pdf' not in content_type.lower() and not url.lower().endswith('.pdf'):
            print(f"Warning: Content-Type is {content_type}, but proceeding anyway")
        
        return response.content
    except requests.exceptions.RequestException as e:
        raise Exception(f"PDF 다운로드 실패: {str(e)}")

def convert_pdf_to_jpg(pdf_content):
    """
    PDF 내용을 JPG 이미지 리스트로 변환합니다.
    """
    try:
        # 임시 PDF 파일 생성
        temp_pdf_path = os.path.join(TEMP_DIR, f"temp_{uuid.uuid4()}.pdf")
        
        with open(temp_pdf_path, 'wb') as f:
            f.write(pdf_content)
        
        # PDF를 이미지로 변환 (DPI를 높이면 품질이 좋아지지만 파일 크기도 커집니다)
        images = convert_from_path(temp_pdf_path, dpi=200, fmt='jpeg')
        
        # 임시 PDF 파일 삭제
        os.remove(temp_pdf_path)
        
        return images
    except Exception as e:
        # 임시 파일 정리
        if os.path.exists(temp_pdf_path):
            os.remove(temp_pdf_path)
        raise Exception(f"PDF 변환 실패: {str(e)}")

def upload_image_to_api(image, upload_url, page_number, headers=None):
    """
    변환된 이미지를 특정 API에 RAW 바디 스트리밍 PUT 요청으로 업로드합니다.
    
    Args:
        image: PIL Image 객체
        upload_url: 업로드할 API URL (기본 URL, 파일명이 자동으로 추가됨)
        page_number: 페이지 번호
        headers: 추가 HTTP 헤더 (선택)
    
    Returns:
        dict: 업로드 결과 정보 (camelCase)
    """
    try:
        # 이미지를 BytesIO로 변환
        img_byte_arr = BytesIO()
        image.save(img_byte_arr, format='JPEG', quality=95)
        img_byte_arr.seek(0)
        
        # 파일명 생성
        filename = f'page_{page_number}.jpg'
        
        # URL에 파일명 추가 (URL이 /로 끝나지 않으면 추가)
        if not upload_url.endswith('/'):
            upload_url += '/'
        full_url = f'{upload_url}{filename}'
        
        # 기본 헤더 설정
        request_headers = {
            'Content-Type': 'image/jpeg'
        }
        
        # 사용자가 제공한 추가 헤더 병합
        if headers:
            request_headers.update(headers)
        
        # PUT 요청으로 RAW 바이너리 데이터 업로드
        response = requests.put(
            full_url,
            data=img_byte_arr.getvalue(),
            headers=request_headers,
            timeout=60
        )
        
        # 응답 확인
        response.raise_for_status()
        
        # 응답 데이터 파싱
        response_data = None
        if response.content:
            try:
                response_data = response.json()
            except:
                response_data = {'raw': response.text}
        
        return {
            'page': page_number,
            'status': 'success',
            'statusCode': response.status_code,
            'message': '업로드 성공',
            'uploadedUrl': full_url,
            'response': response_data
        }
        
    except requests.exceptions.RequestException as e:
        error_message = str(e)
        error_response = None
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_response = e.response.json()
            except:
                error_response = {'raw': e.response.text if e.response.text else None}
        
        return {
            'page': page_number,
            'status': 'failed',
            'statusCode': getattr(e.response, 'status_code', None) if hasattr(e, 'response') else None,
            'message': f'업로드 실패: {error_message}',
            'error': str(e),
            'errorResponse': error_response
        }
    except Exception as e:
        return {
            'page': page_number,
            'status': 'failed',
            'message': f'처리 중 오류: {str(e)}',
            'error': str(e)
        }

@app.route('/health', methods=['GET'])
def health_check():
    """
    헬스 체크 엔드포인트
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/convert', methods=['POST'])
def convert_pdf():
    """
    PDF를 JPG로 변환하고 특정 API에 업로드하는 메인 엔드포인트
    
    Request Body:
    {
        "pdfUrl": "https://your-r2-bucket.com/path/to/file.pdf",
        "uploadUrl": "https://api.example.com/upload/image",
        "headers": {"Authorization": "Bearer token"} (optional)
    }
    
    Response:
    {
        "pdfUrl": "https://...",
        "uploadUrl": "https://...",
        "totalPages": 3,
        "uploaded": 3,
        "failed": 0,
        "results": [
            {
                "page": 1,
                "status": "success",
                "statusCode": 200,
                "message": "업로드 성공"
            },
            ...
        ]
    }
    """
    try:
        # 요청 데이터 파싱
        data = request.get_json()
        
        # 필수 필드 검증
        if not data or 'pdfUrl' not in data:
            return jsonify({
                'error': 'pdfUrl이 필요합니다',
                'message': 'Request body에 "pdfUrl" 필드를 포함해주세요'
            }), 400
        
        if 'uploadUrl' not in data:
            return jsonify({
                'error': 'uploadUrl이 필요합니다',
                'message': 'Request body에 "uploadUrl" 필드를 포함해주세요 (이미지를 업로드할 API URL)'
            }), 400
        
        pdf_url = data['pdfUrl']
        upload_url = data['uploadUrl']
        custom_headers = data.get('headers', {})  # 선택적 헤더
        
        # URL 검증
        if not pdf_url.startswith(('http://', 'https://')):
            return jsonify({
                'error': '유효하지 않은 PDF URL입니다',
                'message': 'pdfUrl은 http:// 또는 https://로 시작해야 합니다'
            }), 400
        
        if not upload_url.startswith(('http://', 'https://')):
            return jsonify({
                'error': '유효하지 않은 uploadUrl입니다',
                'message': 'uploadUrl은 http:// 또는 https://로 시작해야 합니다'
            }), 400
        
        # PDF 다운로드
        pdf_content = download_pdf_from_url(pdf_url)
        
        # PDF를 JPG로 변환
        images = convert_pdf_to_jpg(pdf_content)
        
        if not images:
            return jsonify({
                'error': '변환 실패',
                'message': 'PDF에서 이미지를 생성할 수 없습니다'
            }), 500
        
        # 각 이미지를 API에 업로드
        upload_results = []
        for i, image in enumerate(images, start=1):
            result = upload_image_to_api(image, upload_url, i, custom_headers)
            upload_results.append(result)
        
        # 업로드 통계 계산
        successful_uploads = sum(1 for r in upload_results if r['status'] == 'success')
        failed_uploads = sum(1 for r in upload_results if r['status'] == 'failed')
        
        # 응답 반환 (camelCase 형식)
        return jsonify({
            'pdfUrl': pdf_url,
            'uploadUrl': upload_url,
            'totalPages': len(images),
            'uploaded': successful_uploads,
            'failed': failed_uploads,
            'results': upload_results,
            'status': 'completed' if failed_uploads == 0 else 'partial_success' if successful_uploads > 0 else 'failed'
        }), 200 if failed_uploads == 0 else 207  # 207 Multi-Status for partial success
        
    except Exception as e:
        return jsonify({
            'error': '처리 중 오류 발생',
            'message': str(e)
        }), 500

@app.route('/convert/info', methods=['POST'])
def get_pdf_info():
    """
    PDF 정보를 반환하는 엔드포인트 (페이지 수 등)
    
    Request Body:
    {
        "pdfUrl": "https://your-r2-bucket.com/path/to/file.pdf"
    }
    
    Response:
    {
        "pdfUrl": "https://...",
        "pages": 5,
        "status": "success"
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'pdfUrl' not in data:
            return jsonify({
                'error': 'pdfUrl이 필요합니다'
            }), 400
        
        pdf_url = data['pdfUrl']
        
        # PDF 다운로드
        pdf_content = download_pdf_from_url(pdf_url)
        
        # PDF를 이미지로 변환하여 페이지 수 확인
        images = convert_pdf_to_jpg(pdf_content)
        
        return jsonify({
            'pdfUrl': pdf_url,
            'pages': len(images),
            'status': 'success'
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': '처리 중 오류 발생',
            'message': str(e)
        }), 500

@app.route('/', methods=['GET'])
def home():
    """
    API 홈 페이지
    """
    return jsonify({
        'service': 'PDF to JPG Converter & Upload API',
        'version': '2.0.0',
        'description': 'PDF를 JPG로 변환하고 지정된 API에 자동 업로드합니다',
        'endpoints': {
            'GET /': 'API 정보',
            'GET /health': '헬스 체크',
            'POST /convert': 'PDF를 JPG로 변환하고 API에 업로드',
            'POST /convert/info': 'PDF 정보 조회 (페이지 수)'
        },
        'documentation': {
            '/convert': {
                'method': 'POST',
                'description': 'PDF를 다운로드하여 JPG로 변환한 후 각 페이지를 지정된 API에 RAW 바디 스트리밍 PUT 요청으로 업로드합니다',
                'body': {
                    'pdfUrl': 'PDF 파일의 URL (필수)',
                    'uploadUrl': '이미지를 업로드할 API 기본 URL (필수, PUT /upload-image/:filename 형식)',
                    'headers': '업로드 요청에 포함할 헤더 (선택, 예: Authorization)'
                },
                'example': {
                    'pdfUrl': 'https://your-r2-bucket.com/file.pdf',
                    'uploadUrl': 'https://pdf-to-summary-api.moveto.workers.dev/upload-image',
                    'headers': {
                        'Authorization': 'Bearer your-token-here'
                    }
                },
                'response_example': {
                    'pdfUrl': 'https://your-r2-bucket.com/file.pdf',
                    'uploadUrl': 'https://api.example.com/upload/image',
                    'totalPages': 3,
                    'uploaded': 3,
                    'failed': 0,
                    'status': 'completed',
                    'results': [
                        {
                            'page': 1,
                            'status': 'success',
                            'statusCode': 200,
                            'message': '업로드 성공'
                        }
                    ]
                }
            },
            '/convert/info': {
                'method': 'POST',
                'description': 'PDF 파일의 페이지 수를 조회합니다',
                'body': {
                    'pdfUrl': 'PDF 파일의 URL (필수)'
                },
                'example': {
                    'pdfUrl': 'https://your-r2-bucket.com/file.pdf'
                }
            }
        }
    }), 200

if __name__ == '__main__':
    # 로그 디렉토리 생성
    if not os.path.exists('logs'):
        os.makedirs('logs')
    
    # 개발 환경에서만 Flask 내장 서버 사용
    if ENV == 'development':
        logger.info(f"Starting development server on port {PORT}")
        app.run(debug=DEBUG, host='0.0.0.0', port=PORT)
    else:
        logger.warning("Production 환경에서는 Gunicorn을 사용하세요: gunicorn -c gunicorn_config.py app:app")

