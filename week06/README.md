# 6주차

## 오늘 배운 내용
- Dockerfile (FROM, WORKDIR, COPY, RUN, ENV, EXPOSE, CMD)
- 레이어 캐시 (자주 바뀌는 것을 뒤에 두기)
- ghcr.io에 이미지 push/pull로 공유
- 설정 우선순위: 코드 < ENV < `-e`

## 새로 배운 명령어
```bash
docker build -t guestbook:v1 .
docker rmi guestbook:v1
docker tag guestbook:v1 ghcr.io/아이디/guestbook:v1
docker push ghcr.io/아이디/guestbook:v1
git tag week06
```
