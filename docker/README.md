
## Use

### Requirements

[docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

### Build

From the root of the project, run

```
$VERSION=<desired pherkin version>
docker build -t pherkin:$VERSION --build-arg VERSION=$VERSION ./docker
```

### Run

In the directory containing your `./features/` directory:

```
docker run -it --rm \
    --user $(id -u) \
    --volume $PWD:/work \
    --workdir /work \
    pherkin:$VERSION [options]
```

