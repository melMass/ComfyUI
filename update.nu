def main [] {
    let root = $env.FILE_PWD
    let models = $"($root)/models"


    # echo $"(ansi green)Running from ($here)"

    cd $models

    # find all symlinks
    ls -la | 
        where not ($it.target | is-empty) | 
        select name target | 
        sort-by name | 
        save -f links.nuon

    # remove them
    open links.nuon | each {|p| rm $p.name }


    cd $root

    git checkout master
    git fetch
    git pull
    git checkout -
    git merge master

    cd $models

    # resymlink them
    open links.nuon | each {|p| link -a $p.target $p.name }
}
