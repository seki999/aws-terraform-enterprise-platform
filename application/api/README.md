# FastAPI 服务

提供健康、就绪、Items、Jobs、上传预签名 URL 和 Prometheus 指标端点。AWS SDK 使用执行环境 Role，不读取代码中的静态密钥。

```bash
python -m pip install -r requirements-dev.txt
python -m pytest
uvicorn app.main:app --reload
```

`/ready` 仅对已配置依赖做检查。生产中应结合超时、连接池、迁移工具、鉴权、限流和可观测性增强。

