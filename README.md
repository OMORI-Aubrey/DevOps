# DevOps

2026-2 인하공업전문대학 컴퓨터정보공학과 DevOps 실습 저장소

## 실습 환경
- OS: Windows + WSL2 (Ubuntu 26.04)
- 도구: Git, GitHub CLI(gh), Docker Desktop, Docker Compose

## 주차별 내용

| 주차 | 교안 | 주요 내용 | 링크 |
|---|---|---|---|
| 1주차 | 강의 오리엔테이션 | DevOps 개념, 수업 운영 | 없음 |
| 2주차 | 01. 실습 환경 구축과 버전 관리 기초 | 가상화, WSL2, 리눅스 명령어, Git/GitHub | [week02](./week02/) |
| 3주차 | 02. 셸 스크립팅 | 로컬 LLM(Ollama + Qwen) 실행, 셸 스크립트 자동화 | [week03](./week03/) |
| 4주차 | 03. 자동화와 협업 | grep/find/파이프, 백업 스크립트, 브랜치 → PR → Conflict → Merge | [week04](./week04/) |
| 5주차 | 05. 도커 w/ GitHub Issue | 컨테이너 개념, docker 명령어, Issue → Branch → PR → Merge | [week05](./week05/) |
| 6주차 | 06. 도커파일 | Dockerfile, 레이어 캐시, ghcr.io 이미지 공유 | [week06](./week06/) |
| 7주차 | 07. 도커 컴포즈 | compose, 볼륨, healthcheck, nginx + scale | [week07](./week07/) |

## 실습 애플리케이션
- [guestbook](./guestbook/) - 6주차부터 계속 업데이트하는 방명록 앱 (Flask + Redis)
  - 6주차: Dockerfile로 이미지화 (`git tag week06`)
  - 7주차: compose.yaml, nginx.conf 추가 (`git tag week07`)
