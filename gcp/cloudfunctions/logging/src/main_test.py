import main
import logging
import pytest


def test_sample(caplog: pytest.LogCaptureFixture):
    with caplog.at_level(logging.DEBUG):
        main.main({})
        logs = caplog.text.split("\n")
        assert "msg log" in logs[0]
        assert "json dumps log" in logs[1]
