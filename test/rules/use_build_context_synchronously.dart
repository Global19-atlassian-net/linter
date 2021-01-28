// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_build_context_synchronously`

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void f(BuildContext context) {}

void func(Function f) {}

class MyWidget extends StatefulWidget {
  @override
  State createState() => _MyState();
}

void directAccess(BuildContext context) async {
  await Future<void>.delayed(Duration());

  var renderObject = context.findRenderObject(); // LINT
}

bool binaryExpression(BuildContext context) async {
  bool f2(BuildContext context) => true;

  f2(context);

  await Future<void>.delayed(Duration());

  return true || f2(context); // LINT
}

class C {
  BuildContext context;
  C(this.context);
}

class _MyState extends State<MyWidget> {
  void methodUsingStateContext1() async {
    // Uses context from State.
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());

    // Not ok. Used after an async gap without checking mounted.
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  void methodUsingStateContext2() async {
    // Uses context from State.
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());

    if (!mounted) return;

    // OK. mounted checked first.
    Navigator.of(context).pushNamed('routeName'); // OK
  }

  void methodUsingStateContext3() async {
    f(context);

    await Future<void>.delayed(Duration());

    f(context); // LINT
  }

  void methodUsingStateContext4() async {
    void f(BuildContext context) {}

    f(context);

    await Future<void>.delayed(Duration());

    f(context); // LINT
  }

  void methodUsingStateContext5() async {
    C(context);

    await Future<void>.delayed(Duration());

    C(context); // LINT
  }

  // Method given a build context to use.
  void methodWithBuildContextParameter1(BuildContext context) async {
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // Same as above, but using a conditional path.
  void methodWithBuildContextParameter2(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // Another conditional path.
  void methodWithBuildContextParameter2a(BuildContext context) async {
    bool f() => true;
    while (f()) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // And another.
  void methodWithBuildContextParameter2b(BuildContext context) async {
    for (var i = 0; i < 1; ++i) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // And another.
  void methodWithBuildContextParameter2c(BuildContext context) async {
    for (var i in [1]) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // And another.
  void methodWithBuildContextParameter2d(BuildContext context) async {
    bool f() => true;
    do {
      await Future<void>.delayed(Duration());
    } while (f());
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // Mounted checks are deliberately naive.
  void methodWithBuildContextParameter3(BuildContext context) async {
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());

    if (!mounted) return;

    // Mounted doesn't cover provided context but that's by design.
    Navigator.of(context).pushNamed('routeName'); // OK
  }

  @override
  Widget build(BuildContext context) => const Placeholder();
}

void topLevel(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName'); // OK

  await Future<void>.delayed(Duration());
  Navigator.of(context).pushNamed('routeName'); // LINT
}

void topLevel2(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName'); // OK

  await Future<void>.delayed(Duration());
  // todo (pq): validate other conditionals (for, while, do, ...)
  // OR: should that be disallowed in another lint?
  if (true) {
    Navigator.of(context).pushNamed('routeName'); // LINT
  }
}

void topLevel3(BuildContext context) async {
  while (true) {
    // OK the first time only!
    Navigator.of(context).pushNamed('routeName'); // TODO: LINT
    await Future<void>.delayed(Duration());
  }
}

void closure(BuildContext context) async {
  await Future<void>.delayed(Duration());

  // todo (pq): what about closures?
  func(() {
    f(context); // TODO: LINT
  });
}
