# 7주차

## 오늘 배운 내용
- 컨테이너 하나 = 역할 하나 (앱과 DB를 나눠서 띄우기)
- compose.yaml로 여러 컨테이너를 파일 하나로 정의
- 서비스 이름이 곧 DNS 주소 (`REDIS_HOST: "redis"`)
- 볼륨 - 컨테이너를 지워도 데이터는 남음 (`down -v`는 데이터까지 삭제)
- `ports:` 없는 서비스는 외부에 노출되지 않음 (네트워크 격리)
- `.env`로 비밀번호 분리, `healthcheck`로 준비 완료 확인
- nginx 리버스 프록시 + `--scale`로 web 여러 개 띄우기

## 새로 배운 명령어
```bash
docker compose up -d
docker compose ps
docker compose logs -f web
docker compose restart web
docker compose down        # 컨테이너, 네트워크 삭제
docker compose down -v     # 볼륨까지 삭제 (데이터 사라짐)
docker compose config -q   # yaml 검사
docker compose up -d --scale web=3
docker compose watch --no-up
docker volume ls
```
