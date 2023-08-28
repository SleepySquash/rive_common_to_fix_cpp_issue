#ifndef _RIVE_MAC_UTILS_HPP_
#define _RIVE_MAC_UTILS_HPP_

#include "rive/rive_types.hpp"
#include "rive/span.hpp"
#include <string>

#ifdef RIVE_BUILD_FOR_APPLE

#if defined(RIVE_BUILD_FOR_OSX)
#include <ApplicationServices/ApplicationServices.h>
#elif defined(RIVE_BUILD_FOR_IOS)
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CGImage.h>
#endif

template <size_t N, typename T> class AutoSTArray
{
    T m_storage[N];
    T* m_ptr;
    const size_t m_count;

public:
    AutoSTArray(size_t n) : m_count(n)
    {
        m_ptr = m_storage;
        if (n > N)
        {
            m_ptr = new T[n];
        }
    }
    ~AutoSTArray()
    {
        if (m_ptr != m_storage)
        {
            delete[] m_ptr;
        }
    }

    T* data() const { return m_ptr; }

    T& operator[](size_t index)
    {
        assert(index < m_count);
        return m_ptr[index];
    }
};

constexpr inline uint32_t make_tag(uint8_t a, uint8_t b, uint8_t c, uint8_t d)
{
    return (a << 24) | (b << 16) | (c << 8) | d;
}

static inline std::string tag2str(uint32_t tag)
{
    std::string str = "abcd";
    str[0] = (tag >> 24) & 0xFF;
    str[1] = (tag >> 16) & 0xFF;
    str[2] = (tag >> 8) & 0xFF;
    str[3] = (tag >> 0) & 0xFF;
    return str;
}

template <typename T> class AutoCF
{
    T m_obj;

public:
    AutoCF(T obj = nullptr) : m_obj(obj) {}
    AutoCF(const AutoCF& other)
    {
        if (other.m_obj)
        {
            CFRetain(other.m_obj);
        }
        m_obj = other.m_obj;
    }
    AutoCF(AutoCF&& other)
    {
        m_obj = other.m_obj;
        other.m_obj = nullptr;
    }
    ~AutoCF()
    {
        if (m_obj)
        {
            CFRelease(m_obj);
        }
    }

    AutoCF& operator=(const AutoCF& other)
    {
        if (m_obj != other.m_obj)
        {
            if (other.m_obj)
            {
                CFRetain(other.m_obj);
            }
            if (m_obj)
            {
                CFRelease(m_obj);
            }
            m_obj = other.m_obj;
        }
        return *this;
    }

    void reset(T obj)
    {
        if (obj != m_obj)
        {
            if (m_obj)
            {
                CFRelease(m_obj);
            }
            m_obj = obj;
        }
    }

    operator T() const { return m_obj; }
    operator bool() const { return m_obj != nullptr; }
    T get() const { return m_obj; }
};

static inline float find_float(CFDictionaryRef dict, const void* key)
{
    auto num = (CFNumberRef)CFDictionaryGetValue(dict, key);
    assert(num);
    float value = 0;
    CFNumberGetValue(num, kCFNumberFloat32Type, &value);
    return value;
}

static inline uint32_t find_u32(CFDictionaryRef dict, const void* key)
{
    auto num = (CFNumberRef)CFDictionaryGetValue(dict, key);
    assert(num);
    assert(!CFNumberIsFloatType(num));
    uint32_t value = 0;
    CFNumberGetValue(num, kCFNumberSInt32Type, &value);
    return value;
}

static inline uint32_t number_as_u32(CFNumberRef num)
{
    uint32_t value;
    CFNumberGetValue(num, kCFNumberSInt32Type, &value);
    return value;
}

static inline float number_as_float(CFNumberRef num)
{
    float value;
    CFNumberGetValue(num, kCFNumberFloat32Type, &value);
    return value;
}

namespace rive
{
AutoCF<CGImageRef> DecodeToCGImage(Span<const uint8_t>);
AutoCF<CGImageRef> FlipCGImageInY(AutoCF<CGImageRef>);
} // namespace rive

#endif
#endif
