import os
import sqlalchemy


def connect_tcp_socket() -> sqlalchemy.engine.base.Engine:
    db_host = "127.0.0.1"
    db_user = os.environ["DB_USER"]
    db_pass = os.environ["DB_PASS"]
    db_name = os.environ["DB_NAME"]
    db_port = int(os.environ["DB_PORT"])

    return sqlalchemy.create_engine(
        sqlalchemy.engine.url.URL.create(
            drivername="mysql+pymysql",
            username=db_user,
            password=db_pass,
            host=db_host,
            port=db_port,
            database=db_name,
        ),
    )


with connect_tcp_socket().connect() as conn:
    result = conn.execute(sqlalchemy.text("SHOW DATABASES"))
    for row in result:
        print(row)
