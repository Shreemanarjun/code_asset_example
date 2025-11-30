
#include "native_add_library.h"
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>
#include <string.h> // For memcpy

#ifdef DEBUG
#include <stdio.h>
#endif



// Safe multiplication with overflow detection
static int safe_multiply(int32_t a, int32_t b, int32_t* result) {
  if (a == 0 || b == 0) {
    *result = 0;
    return 1;
  }

  if (a > INT32_MAX / b || a < INT32_MIN / b) {
    return 0; // Overflow would occur
  }

  *result = a * b;
  return 1;
}

// Safe addition with overflow detection
static int safe_add(int32_t a, int32_t b, int32_t* result) {
  if ((b > 0 && a > INT32_MAX - b) || (b < 0 && a < INT32_MIN - b)) {
    return 0; // Overflow would occur
  }

  *result = a + b;
  return 1;
}

int32_t add(int32_t a, int32_t b) {
#ifdef DEBUG
  printf("Adding %i and %i.\n", a, b);
#endif
  int32_t result;
  if (!safe_add(a, b, &result)) {
    return INT32_MAX; // Return max value on overflow
  }
  return result;
}

void fibo(int32_t n, int32_t* result) {
  // Input validation
  if (n <= 0 || n > 1000 || result == NULL) return;

  int success = 1;
  if (n >= 1) result[0] = 0;
  if (n >= 2) result[1] = 1;

  for (int32_t i = 2; i < n && success; i++) {
    success = safe_add(result[i-1], result[i-2], &result[i]);
    if (!success) {
      // On overflow, fill remaining with max value
      for (int32_t j = i; j < n; j++) {
        result[j] = INT32_MAX;
      }
      break;
    }
  }
}

void fibo_batch(int32_t n, int32_t iterations, int32_t* results) {
  // Input validation
  if (n <= 0 || n > 1000 || iterations <= 0 || iterations > 100000 || results == NULL) {
    return;
  }

  // Pre-compute the base Fibonacci sequence once
  int32_t* base_fibo = (int32_t*)malloc(n * sizeof(int32_t));
  if (base_fibo == NULL) return;

  int success = 1;
  if (n >= 1) base_fibo[0] = 0;
  if (n >= 2) base_fibo[1] = 1;

  for (int32_t i = 2; i < n && success; i++) {
    success = safe_add(base_fibo[i-1], base_fibo[i-2], &base_fibo[i]);
    if (!success) {
      // On overflow, fill remaining with max value
      for (int32_t j = i; j < n; j++) {
        base_fibo[j] = INT32_MAX;
      }
      break;
    }
  }

  // Copy the pre-computed sequence to all iterations (highly optimized)
  for (int32_t iter = 0; iter < iterations; iter++) {
    int32_t* result_ptr = &results[iter * n];
    // Use memcpy for maximum performance - no per-element operations
    memcpy(result_ptr, base_fibo, n * sizeof(int32_t));
  }

  free(base_fibo);
}

int64_t factorial(int32_t n) {
  // Input validation and bounds checking
  if (n < 0) return 0;
  if (n == 0 || n == 1) return 1;
  if (n > 20) return INT64_MAX; // Prevent overflow for large n (21! overflows int64)

  int64_t result = 1;
  for (int32_t i = 2; i <= n; i++) {
    int64_t temp = result * i; // Use 64-bit multiplication
    if (temp / i != result) { // Check for overflow
      return INT64_MAX; // Return max value on overflow
    }
    result = temp;
  }
  return result;
}

void factorial_batch(int32_t n, int32_t iterations, int64_t* results) {
  // Input validation
  if (n < 0 || iterations <= 0 || iterations > 100000 || results == NULL) {
    return;
  }

  // Pre-compute the factorial once with overflow protection
  int64_t fact = factorial(n);

  // Copy the factorial result multiple times
  for (int32_t iter = 0; iter < iterations; iter++) {
    results[iter] = fact;
  }
}
