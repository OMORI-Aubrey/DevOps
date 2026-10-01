# 5주차 - Docker

## 오늘 배운 내용
- 하이퍼바이저(VM) vs 컨테이너 (커널 공유, 가볍고 빠름)
- 이미지(붕어빵 틀)와 컨테이너(붕어빵)의 관계
- 컨테이너 격리 (namespace, cgroup)
- Docker Desktop 설치 및 nginx 컨테이너 실행
- GitHub Issue → Branch → PR → Merge 흐름

## 새로 배운 명령어
```bash
docker run -d -p 8080:80 --name web nginx 
docker ps -a 
docker images 
docker exec -it web bash 
docker stop web
docker rm -f web 
docker run --rm -v "$PWD:/app" -w /app python:3.12-slim python test.py
```

## 혼자서 해보기 - curl 결과

```bash
$ curl http://localhost:8091
<h1>Welcome to nginx1</h1>

$ curl http://localhost:8092
<h1>Welcome to nginx2</h1>

$ curl http://localhost:8093
<h1>Welcome to nginx3</h1>

```
