# ---------------------------------------------------------------
# 학생 과제: 아래 각 줄이 무엇을 하는지 주석으로 설명을 달아보세요.
# ---------------------------------------------------------------

# 기반 이미지: Python 3.12의 가벼운 slim 버전
FROM python:3.12-slim

# 작업 디렉터리를 /app으로 지정
WORKDIR /app

# 빌드 컨텍스트의 requirements.txt를 이미지의 /app으로 복사
# 빌드할 때 패키지 설치 (결과가 이미지에 남음)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 빌드 컨텍스트의 나머지 파일 전체를 /app으로 복사
COPY . .

# 빌드할 때 일반 사용자 appuser 생성
# 이후 명령과 컨테이너 실행을 adduser 권한으로 수행
RUN useradd -m appuser
USER appuser

# 환경변수 기본값을 이미지에 저장
ENV APP_TITLE="InhaTC DevOps 방명록" \
    THEME_COLOR="#0054A6"

# 5000번 포트를 쓴다고 문서화 (실제로 열리지는 않음)
EXPOSE 5000

# 컨테이너가 시작할 때 app.py 실행
CMD ["python", "app.py"]
