EVM将数据存为storage或memory。在开发合约时，准确地理解如何使用这个操作至关重要。否则可以因为利用不适当地初始化变量来产生有漏洞的合约。

坑点分析

函数中的局部变量根据它们的类型默认为存在内存中。未初始化的本地存储变量可以指向合约中其他意想不到的存储变量，从而导致有意或无意的漏洞。

让我们考虑下面这个相对简单的名称注册合约：
image

这个简单的名称注册合约只有一个函数。当合约解锁时，它允许任何人注册一个名称（作为bytes32哈希），并将该名称映射到地址上。

不幸的是，这个注册器最初是锁定的，而且第23行上的require阻止了register()函数添加名称记录。然而，在这个合约中存在一个漏洞，它允许名称注册，而不顾及unlocked的变量。

为了讨论这个漏洞，首先我们需要了解存储在Solidity中是如何工作的。简单来说，状态变量按照合约中出现的顺序保存在slot中（它们可以组合在一起，但不是在这个例子中的问题，所以不过多讨论）。

因此，解锁存在于slot 0中，registeredNameRecord 存在于slot 1中，resolve存在于slot 2中。每个slot都是32字节大小（我们现在忽略了映射的复杂性）。

布尔值unlocked，对于 false看起来像0x000... 0（64个0，不包括0x）或对于true来说是0x000... 1（63个0）。 正如你所看到的，在这个特殊的例子中存在着巨大的存储空间。

我们需要的下一个信息是 Solidity 默认的复杂数据类型（如结构），在初始化时作为局部变量存储它们。因此，新记录在第16行默认为storage。这种漏洞是由于newRecord没有初始化而引起的。因为它默认为存储，它成为一个指向存储的指针，因为它是未初始化的，它指向了slot 0（即存储解锁的地方）。

值得注意的是，在第17和18行上，我们为_name设置了

nameRecord.name

并为

_mappedAddress设置了

nameRecord.mappedAddress

这实际上改变slot 0和slot 1的存储位置，这两个位置同时修改了已解锁的存储空间和与

registeredNameRecord

相关的slot存储位置。

这意味着，只需通过寄存器函数的bytes32名称参数，就可以直接修改解锁。因此，如果名称的最后一个字节是非零的，它将修改存储slot 0的最后一个字节，并直接将unlocked更改为true。

这样的_name值将在unlocked为true的时候通过在第23行上的require()。在Remix中尝试一下这个例子。

注意，如果_name使用了以下值的函数：

0x0000000000000000000000000000000000000000000000000000000000000001

则会通过执行。

避坑技巧

Solidity的编译器将未初始化的存储变量作为了警告，因此开发者在构建智能合约时应该注意这些警告。当前版本的mist(0.10)不允许编译这些合约。在处理复杂类型时，要明确使用内存还是存储，以确保它们按预期运行。

真实案例：蜜罐OpenAddressLottery和CryptoRoulette

有一个名为OpenAdditsLottery 的Honey pot使用了另外一个未初始化的存储变量，从一些可能的黑客那里收集以太币。

这份合约相当有深度，在Reddit上有一个深度讨论的帖子，感兴趣的话可以去研究一下。

Reddit地址：

https://www.reddit.com/r/ethdev/comments/7wp363/how_does_this_honeypot_work_it_seems_like_a/

另一个honey pot叫CryptoRoulette，也利用了这个技巧来收集一些以太币。你可以在下面地址找到详细的解读：

https://medium.com/@jsanjuas/an-analysis-of-a-couple-ethereum-honeypot-contracts-5c07c95b0a8d

