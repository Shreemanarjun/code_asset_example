// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdint.h>

#if _WIN32
#define MYLIB_EXPORT __declspec(dllexport)
#else
#define MYLIB_EXPORT
#endif

MYLIB_EXPORT int32_t add(int32_t a, int32_t b);
MYLIB_EXPORT void fibo(int32_t n, int32_t* result);
MYLIB_EXPORT void fibo_batch(int32_t n, int32_t iterations, int32_t* results);
MYLIB_EXPORT int64_t factorial(int32_t n);
MYLIB_EXPORT void factorial_batch(int32_t n, int32_t iterations, int64_t* results);
MYLIB_EXPORT double monte_carlo_pi(int64_t num_samples);
MYLIB_EXPORT void monte_carlo_pi_batch(int64_t num_samples, int32_t iterations, double* results);
MYLIB_EXPORT void matrix_multiply(int32_t m, int32_t k, int32_t n, const double* A, const double* B, double* C);
MYLIB_EXPORT void matrix_multiply_batch(int32_t m, int32_t k, int32_t n, const double* A, const double* B, int32_t iterations, double* results);
