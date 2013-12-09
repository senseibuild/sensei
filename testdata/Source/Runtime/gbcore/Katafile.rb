
project 'gbcore' do
    deps = find_packages 'gbutils'

    cc = task :cc
    ld = task :ld

    build glob('**/*.c', '**/*.cpp'), cc
    build cc, ld do
        using deps
        output File.join(BUILDDIR, 'gbcore'), :root
        shared
    end

    outputs ld
end
