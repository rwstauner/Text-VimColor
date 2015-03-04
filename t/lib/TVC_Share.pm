use strict;
use warnings;

package # no_index
  TVC_Share;

# Use a separate module to initiate the test share dir
# so that we can pass a simple -MTVC_Share to perl for subprocesses.

use Test::File::ShareDir::Dist { 'Text-VimColor' => 'share/' };

1;
