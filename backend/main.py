from fastapi.middleware.cors import CORSMiddleware
import os
from datetime import datetime
from typing import Optional, List
from sqlmodel import Field, Session, SQLModel, create_engine, select
from fastapi import FastAPI

db_user = os.getenv("DB_USER", "admin")
db_pass = os.getenv("DB_PASSWORD", "password") # secretsから注入される
db_host = os.getenv("DB_HOST", "localhost")
db_name = os.getenv("DB_NAME", "appdb")

DATABASE_URL = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}:3306/{db_name}"

# 2. Engineの作成
engine = create_engine(DATABASE_URL, echo=True) # echo=Trueで発行SQLをログに出す

# 3. モデル定義（これがテーブル構造になる）
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str
    created_at: datetime = Field(default_factory=datetime.now)

app = FastAPI()

# 4. 起動時にテーブルを作成し、接続をテストする
@app.on_event("startup")
def on_startup():
    SQLModel.metadata.create_all(engine)
    
    # 接続テスト：ユーザーが一人もいなければ作成してみる
    with Session(engine) as session:
        statement = select(User)
        results = session.exec(statement)
        if not results.first():
            test_user = User(username="admin_k")
            session.add(test_user)
            session.commit()
            print("--- Database Initialized and Test User Created! ---")

@app.get("/api/users", response_model=List[User])
def get_users():
    with Session(engine) as session:
        return session.exec(select(User)).all()

# healthチェック専用
@app.get("/health")
def health_check():
    return {"status": "ok"}


# フロントエンド（Next.js）との通信を許可する設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/hello")
def read_root():
    return {"Hello": "World from FastAPI"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}