
## つかいかた

```sh:
# install dependencies
bundle install --path vendor/bundle --binstubs

# start web server
./bin/shotgun

# open test page
open http://localhost:9393/
```

## coffeescriptをいじるときはGuardつかってね

```sh:how-to-compile-cofeescript
./bin/guard
```

## logは./log以下に保存されます

```sh:how-to-tail-log
tail -f ./log/*.log
```
