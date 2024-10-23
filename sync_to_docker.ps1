
$containers = @('mettalog', 'hyperon')
$hostSrcDir = "./metta-ec/."

$mettalogDestDir = "/home/user/devspace/metta-ec"
$hyperonDestDir = "/home/metta-ec"

function checkContainerRunning ($container) {
    if (-not $(docker ps --filter "name=$container" --filter "status=running" -q)) {
        echo "Container $container has not been started."
        exit 1
    }
}

function doSync($container, $hostSrc, $containerDest) { 
    $folderExists = $(docker exec $container bash -c "[ -d $containerDest ] && echo 'exists'")
    if ($folderExists -eq "exists") {
        docker exec $container bash -c "rm -r $containerDest"
        echo "Deleted $containerDest from $container"
    }
    docker cp $hostSrc ${container}:${containerDest}
}

foreach ($c in $args) {
    if ($c -in $containers) {
        checkContainerRunning $c
        if ($c -eq "mettalog") {
            doSync $c $hostSrcDir $mettalogDestDir
        }
        elseif ($c -eq "hyperon") {
            doSync $c $hostSrcDir $hyperonDestDir
        }
    }
    else {
        echo "Invalid container. Available containers are '${containers}'"
    }
}