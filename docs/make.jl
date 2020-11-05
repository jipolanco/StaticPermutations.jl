using FastPermutations
using Documenter

DocMeta.setdocmeta!(FastPermutations, :DocTestSetup, :(using FastPermutations);
                    recursive=true)

makedocs(;
    modules=[FastPermutations],
    authors="Juan Ignacio Polanco <jipolanc@gmail.com> and contributors",
    repo="https://github.com/jipolanco/FastPermutations.jl/blob/{commit}{path}#L{line}",
    sitename="FastPermutations.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jipolanco.github.io/FastPermutations.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jipolanco/FastPermutations.jl.git",
)
