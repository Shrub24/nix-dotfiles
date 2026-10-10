"""Pi-Bolt release discovery excludes unpublished or unusable versions."""

import io
import json
import unittest
from unittest.mock import patch

import update


def published(tag, *, draft=False, prerelease=False, asset=True):
    return {
        "tag_name": tag,
        "draft": draft,
        "prerelease": prerelease,
        "assets": [{"name": "pi-bolt-runtime-linux-x64.tar.gz"}] if asset else [],
    }


def response(items, link=""):
    result = io.StringIO(json.dumps(items))
    result.headers = {"Link": link}
    return result


class ReleaseDiscovery(unittest.TestCase):
    def test_selects_latest_usable_stable_release_across_pages(self):
        pages = [
            response([
                published("bolt-v0.12.0", draft=True),
                published("bolt-v0.11.0", prerelease=True),
                published("bolt-v0.10.0", asset=False),
                published("component-v9.0.0"),
                published("bolt-v0.8.0"),
            ], '<https://api.github.com/repos/opensec-git/Pi-Bolt/releases?page=2>; rel="next"'),
            response([published("bolt-v0.9.0")]),
        ]
        with patch.dict(update.os.environ, {}, clear=True), patch.object(update, "urlopen", side_effect=pages) as fetch:
            self.assertEqual(update.release(), "0.9.0")
        self.assertIn("/releases?", fetch.call_args_list[0].args[0].full_url)

    def test_explicit_target_must_be_a_usable_published_release(self):
        with patch.dict(update.os.environ, {"PI_BOLT_UPDATE_VERSION": "0.10.0"}, clear=True), patch.object(update, "urlopen", return_value=response([
            published("bolt-v0.10.0", asset=False), published("bolt-v0.9.0"),
        ])):
            with self.assertRaisesRegex(ValueError, "no matching stable Pi-Bolt release"):
                update.release()

    def test_explicit_target_selects_older_published_release(self):
        with patch.dict(update.os.environ, {"PI_BOLT_UPDATE_VERSION": "0.8.0"}, clear=True), patch.object(update, "urlopen", return_value=response([
            published("bolt-v0.9.0"), published("bolt-v0.8.0"),
        ])):
            self.assertEqual(update.release(), "0.8.0")


if __name__ == "__main__":
    unittest.main()
