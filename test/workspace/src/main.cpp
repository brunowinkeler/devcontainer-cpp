#include <array>
#include <numeric>

int main()
{
    std::array<int, 8> values{};
    std::iota(values.begin(), values.end(), 1);
    return std::accumulate(values.begin(), values.end(), 0) == 36 ? 0 : 1;
}
