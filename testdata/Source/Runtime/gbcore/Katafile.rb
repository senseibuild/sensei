
package 'gbcore' do
    cc = compiler :cc

    build glob('**/*.c', '**/*.cpp'), cc
end
